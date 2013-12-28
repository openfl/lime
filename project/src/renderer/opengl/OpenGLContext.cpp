#include "renderer/opengl/OpenGLContext.h"


int sgDrawCount = 0;
int sgBufferCount = 0;
int sgDrawBitmap = 0;


namespace lime {
	
	
	OpenGLContext::OpenGLContext (WinDC inDC, GLCtx inOGLCtx) {
		
		HardwareContext::current = this;
		mDC = inDC;
		mOGLCtx = inOGLCtx;
		mWidth = 0;
		mHeight = 0;
		mLineWidth = -1;
		mPointsToo = true;
		mBitmapSurface = 0;
		mBitmapTexture = 0;
		mUsingBitmapMatrix = false;
		mLineScaleNormal = -1;
		mLineScaleV = -1;
		mLineScaleH = -1;
		mPointSmooth = true;
		mColourArrayEnabled = false;
		mThreadId = GetThreadId ();
		mAlphaMode = amUnknown;
		
		const char *str = (const char *)glGetString (GL_VENDOR);
		
		if (str && !strncmp (str, "Intel", 5))
			mPointSmooth = false;
		
		#if defined(LIME_GLES)
		mQuality = sqLow;
		#else
		mQuality = sqBest;
		#endif
		
	}
	
	
	OpenGLContext::~OpenGLContext () {}
	
	
	void OpenGLContext::BeginBitmapRender (Surface *inSurface, uint32 inTint, bool inRepeat, bool inSmooth) {
		
		if (!mUsingBitmapMatrix) {
			
			mUsingBitmapMatrix = true;
			PushBitmapMatrix ();
			
		}
		
		if (mBitmapSurface == inSurface && mTint == inTint)
			return;
		
		mTint = inTint;
		mBitmapSurface = inSurface;
		inSurface->Bind (*this, 0);
		mBitmapTexture = inSurface->GetOrCreateTexture (*this);
		mBitmapTexture->BindFlags (inRepeat, inSmooth);
		
		PrepareBitmapRender ();
		
	}
	
	
	void OpenGLContext::BeginRender (const Rect &inRect, bool inForHitTest) {
		
		if (!inForHitTest) {
			
			#ifndef LIME_GLES
			#ifndef SDL_OGL
			#ifndef GLFW_OGL
			wglMakeCurrent (mDC, mOGLCtx);
			#endif
			#endif
			#endif
		 	
			if (mZombieTextures.size ()) {
				
				glDeleteTextures (mZombieTextures.size (), &mZombieTextures[0]);
				mZombieTextures.resize (0);
				
			}
			
			// Force dirty
			mViewport.w = -1;
			SetViewport (inRect);
			
			//#ifndef LIME_FORCE_GLES2
			glEnable (GL_BLEND);
			//#endif
			
			if (mAlphaMode == amPremultiplied)
				glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
			else
				glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			
			#ifdef WEBOS
			glColorMask (GL_TRUE, GL_TRUE, GL_TRUE, GL_FALSE);
			#endif
			
			#ifndef LIME_FORCE_GLES2
			if (mQuality >= sqHigh && mPointSmooth)
				glEnable (GL_POINT_SMOOTH);
			
			if (mQuality >= sqBest)
				glEnable (GL_LINE_SMOOTH);
			#endif
			
			mLineWidth = 99999;
			
			// printf("DrawArrays: %d, DrawBitmaps:%d  Buffers:%d\n", sgDrawCount, sgDrawBitmap, sgBufferCount );
			sgDrawCount = 0;
			sgDrawBitmap = 0;
			sgBufferCount = 0;
			
			OnBeginRender ();
			
		}
		
	}
	
	
	void OpenGLContext::Clear (uint32 inColour, const Rect *inRect) {
		
		Rect r = inRect ? *inRect : Rect (mWidth, mHeight);
		glViewport (r.x, mHeight - r.y1 (), r.w, r.h);
		
		if (r == Rect (mWidth, mHeight)) {
			
			glClearColor ((GLclampf)(((inColour >> 16) & 0xff) / 255.0), (GLclampf)(((inColour >> 8) & 0xff) / 255.0), (GLclampf)(((inColour) & 0xff) / 255.0), (GLclampf)1.0);
			glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
			
		} else {
			
			#ifndef LIME_FORCE_GLES2
			
			// TODO: Clear with a rect
			// TODO: Need replacement call for GLES2
			glColor4f ((GLclampf)(((inColour >> 16) & 0xff) / 255.0), (GLclampf)(((inColour >> 8) & 0xff) / 255.0), (GLclampf)(((inColour) & 0xff) / 255.0), (GLclampf)1.0);
			
			glMatrixMode (GL_MODELVIEW);
			glPushMatrix ();
			glLoadIdentity ();
			glMatrixMode (GL_PROJECTION);
			glPushMatrix ();
			glLoadIdentity ();
			
			glDisable (GL_TEXTURE_2D);
			static GLfloat rect[4][2] = { { -2, -2 }, { 2, -2 }, { 2, 2 }, { -2, 2 } };
			glVertexPointer (2, GL_FLOAT, 0, rect[0]);
			glDrawArrays (GL_TRIANGLE_FAN, 0, 4);
			
			glPopMatrix ();
			glMatrixMode (GL_MODELVIEW);
			glPopMatrix ();
			
			#endif
			
		}
		
		if (r != mViewport) {
			
			glViewport (mViewport.x, mHeight - mViewport.y1 (), mViewport.w, mViewport.h);
			
		}
		
	}
	
	
	void OpenGLContext::CombineModelView (const Matrix &inModelView) {
		
		#ifndef LIME_FORCE_GLES2
		
		// Do not combine ModelView and Projection in fixed-function
		float matrix[] = {
			
			mModelView.m00, mModelView.m10, 0, 0,
			mModelView.m01, mModelView.m11, 0, 0,
			0, 0, 1, 0,
			mModelView.mtx, mModelView.mty, 0, 1
			
		};
		
		glLoadMatrixf (matrix);
		#endif
		
	}
	
	
	Texture *OpenGLContext::CreateTexture (Surface *inSurface, unsigned int inFlags) {
		
		return OGLCreateTexture (inSurface, inFlags);
		
	}
	
	
	void OpenGLContext::DestroyNativeTexture (void *inNativeTexture) {
		
		GLuint tid = (GLuint)(size_t)inNativeTexture;
		
		if (!IsMainThread ()) {
			
			//printf("Warning - leaking texture %d", tid );
			mZombieTextures.push_back (tid);
			
		} else {
			
			glDeleteTextures (1, &tid);
			
		}
		
	}
	
	
	void OpenGLContext::EndBitmapRender () {
		
		if (mUsingBitmapMatrix) {
			
			mUsingBitmapMatrix = false;
			PopBitmapMatrix ();
			
		}
		
		mBitmapTexture = 0;
		mBitmapSurface = 0;
		FinishBitmapRender ();
		
	}
	
	
	void OpenGLContext::EndRender () {}
	
	
	void OpenGLContext::FinishBitmapRender () {
		
		#ifndef LIME_FORCE_GLES2
		glDisable (GL_TEXTURE_2D);
		#ifdef LIME_DITHER
		glEnable (GL_DITHER);
		#endif
		#endif
		
	}
	
	
	void OpenGLContext::Flip () {
		
		#ifndef LIME_GLES
		#ifndef SDL_OGL
		#ifndef GLFW_OGL
		SwapBuffers (mDC);
		#endif
		#endif
		#endif
		
	}
	
	
	void OpenGLContext::FinishDrawing () {
		
		SetColourArray (0);
		
	}
	
	
	void OpenGLContext::OnBeginRender () {
		
		#ifndef LIME_FORCE_GLES2
		glEnableClientState (GL_VERTEX_ARRAY);
		#endif
		
	}
	
	
	void OpenGLContext::PopBitmapMatrix () {
		
		#ifndef LIME_FORCE_GLES2
		glPopMatrix ();
		#endif
		
	}
	
	
	void OpenGLContext::PrepareBitmapRender () {
		
		#ifndef LIME_FORCE_GLES2
		float a = (float)((mTint >> 24) & 0xFF) * one_on_255;
		float c0 = (float)((mTint >> 16) & 0xFF) * one_on_255;
		float c1 = (float)((mTint >> 8) & 0xFF) * one_on_255;
		float c2 = (float)(mTint & 0xFF) * one_on_255;
		if (mAlphaMode == amPremultiplied)
			glColor4f (c0 * a, c1 * a, c2 * a, a);
		else
			glColor4f (c0, c1, c2, a);
		glEnable (GL_TEXTURE_2D);
		glEnableClientState (GL_TEXTURE_COORD_ARRAY);
		#ifdef LIME_DITHER
		if (!inSmooth)
		  glDisable (GL_DITHER);
		#endif
		#endif
		
	}
	
	
	bool OpenGLContext::PrepareDrawing () {
		
		return true;
		
	}
	
	
	void OpenGLContext::PushBitmapMatrix () {
		
		#ifndef LIME_FORCE_GLES2
		glPushMatrix ();
		glLoadIdentity ();
		#endif
		
	}
	
	
	void OpenGLContext::Render (const RenderState &inState, const HardwareCalls &inCalls) {
		
		//#ifndef LIME_FORCE_GLES2
		glEnable (GL_BLEND);
		//#endif
		SetViewport (inState.mClipRect);

		if (mModelView != *inState.mTransform.mMatrix) {
			
			mModelView = *inState.mTransform.mMatrix;
			CombineModelView (mModelView);
			mLineScaleV = -1;
			mLineScaleH = -1;
			mLineScaleNormal = -1;
			
		}
		
		uint32 last_col = 0;
		
		for (int c = 0; c < inCalls.size (); c++) {
			
			HardwareArrays &arrays = *inCalls[c];
			DrawElements &elements = arrays.mElements;
			if (elements.empty ())
				continue;
			
			Vertices &vert = arrays.mVertices;
			Vertices &tex_coords = arrays.mTexCoords;
			bool persp = arrays.mFlags & HardwareArrays::PERSPECTIVE;
			
			if (!arrays.mViewport.empty ()) {
				
				SetViewport (Rect (arrays.mViewport[0], arrays.mViewport[1], arrays.mViewport[2], arrays.mViewport[3]));
				
			}
			
			if (arrays.mFlags & HardwareArrays::BM_ADD) {
				
				glBlendFunc (GL_SRC_ALPHA, GL_ONE);
				
			} else if (arrays.mFlags & HardwareArrays::BM_MULTIPLY) {
				
				glBlendFunc (GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
				
			} else if (arrays.mFlags & HardwareArrays::BM_SCREEN) {
				
				glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_COLOR);
				
			} else if (arrays.mFlags & HardwareArrays::AM_PREMULTIPLIED) {
				
				//printf("Premultiplied\n");
				mAlphaMode = amPremultiplied;
				glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
				
			} else {
				
				//printf("Straight\n");
				mAlphaMode = amStraight;
				glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
				
			}
			
			#ifdef LIME_USE_VBO
			if (!arrays.mVertexBO) {
				
				glGenBuffers (1, &arrays.mVertexBO);
				glBindBuffer (GL_ARRAY_BUFFER, arrays.mVertexBO);
				glBufferData (GL_ARRAY_BUFFER, sizeof(float) * (persp ? 4 : 2) * vert.size (), &vert[0].x, GL_STATIC_DRAW);
				
			} else {
				
				glBindBuffer (GL_ARRAY_BUFFER, arrays.mVertexBO);
				
			}
			
			glVertexPointer (persp ? 4 : 2, GL_FLOAT, 0, 0);
			glBindBuffer (GL_ARRAY_BUFFER, 0);
			#else
			SetPositionData (&vert[0].x, persp);
			#endif
			
			Texture *boundTexture = 0;
			bool tex = arrays.mSurface && tex_coords.size ();
			if (tex) {
				
				boundTexture = arrays.mSurface->GetOrCreateTexture (*this);
				SetTexture (arrays.mSurface, &tex_coords[0].x);
				last_col = -1;
				SetModulatingTransform (inState.mColourTransform);
				
				if (arrays.mFlags & HardwareArrays::RADIAL) {
					
					float focus = ((arrays.mFlags & HardwareArrays::FOCAL_MASK) >> 8) / 256.0;
					if (arrays.mFlags & HardwareArrays::FOCAL_SIGN)
						focus = -focus;
					SetRadialGradient (true, focus);
					
				} else {
					
					SetRadialGradient (0, 0);
					
				}
				
			} else {
				
				boundTexture = 0;
				SetTexture (0, 0);
				SetModulatingTransform (0);
				
			}
			
			if (arrays.mColours.size () == vert.size ()) {
				
				SetColourArray (&arrays.mColours[0]);
				SetModulatingTransform (inState.mColourTransform);
				
			} else {
				
				SetColourArray (0);
				
			}
			
			int n = elements.size ();
			if (!PrepareDrawing ())
				n = 0;
			
			sgBufferCount++;
			for (int e = 0; e < n; e++) {
				
				DrawElement draw = elements[e];
				
				if (boundTexture) {
					
					boundTexture->BindFlags (draw.mBitmapRepeat, draw.mBitmapSmooth);
					#ifndef LIME_FORCE_GLES2
					#ifdef LIME_DITHER
					if (!inSmooth)
						glDisable (GL_DITHER);
					#endif
					#endif
					
				} else {
					
					int col = inState.mColourTransform->Transform (draw.mColour);
					if (c == 0 || last_col != col) {
						
						last_col = col; 
						SetSolidColour (col);
						
					}
					
				}
				
				if ((draw.mPrimType == ptLineStrip || draw.mPrimType == ptPoints || draw.mPrimType == ptLines) && draw.mCount > 1) {
					
					if (draw.mWidth < 0) {
						
						SetLineWidth (1.0);
						
					} else if (draw.mWidth == 0) {
						
						SetLineWidth (0.0);
						
					} else {
						
						switch (draw.mScaleMode) {
							
							case ssmNone:
								SetLineWidth (draw.mWidth);
								break;
							
							case ssmNormal:
							case ssmOpenGL:
								if (mLineScaleNormal < 0)
									mLineScaleNormal = sqrt (0.5 * ((mModelView.m00 * mModelView.m00) + (mModelView.m01 * mModelView.m01) + (mModelView.m10 * mModelView.m10) + (mModelView.m11 * mModelView.m11)));
								SetLineWidth (draw.mWidth * mLineScaleNormal);
								break;
							
							case ssmVertical:
								if (mLineScaleV < 0)
									mLineScaleV = sqrt ((mModelView.m00 * mModelView.m00) + (mModelView.m01 * mModelView.m01));
								SetLineWidth (draw.mWidth * mLineScaleV);
								break;
							
							case ssmHorizontal:
								if (mLineScaleH <0)
									mLineScaleH = sqrt ((mModelView.m10 * mModelView.m10) + (mModelView.m11 * mModelView.m11));
								SetLineWidth (draw.mWidth * mLineScaleH);
								break;
							
						}
						
					}
					
					if (mPointsToo && mLineWidth > 1.5 && draw.mPrimType != ptLines)
						glDrawArrays (GL_POINTS, draw.mFirst, draw.mCount);
					
				}
				
				//printf("glDrawArrays %d : %d x %d\n", draw.mPrimType, draw.mFirst, draw.mCount );
				
				sgDrawCount++;
				glDrawArrays (sgOpenglType[draw.mPrimType], draw.mFirst, draw.mCount);
				
				//#ifndef LIME_FORCE_GLES2
				#ifdef LIME_DITHER
				if (boundTexture && !draw.mBitmapSmooth)
					glEnable (GL_DITHER);
				#endif
				//#endif
				
			}
			
			FinishDrawing ();
			
		}
		
	}
	
	
	void OpenGLContext::RenderBitmap (const Rect &inSrc, int inX, int inY) {
		
		UserPoint vertex[4];
		UserPoint tex[4];
		
		for (int i = 0; i < 4; i++) {
			
			UserPoint t (inSrc.x + ((i & 1) ? inSrc.w : 0), inSrc.y + ((i > 1) ? inSrc.h : 0)); 
			tex[i] = mBitmapTexture->PixelToTex (t);
			vertex[i] = UserPoint (inX + ((i & 1) ? inSrc.w : 0), inY + ((i > 1) ? inSrc.h : 0));
			 
		}
		
		SetBitmapData (&vertex[0].x, &tex[0].x);
		
		glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);
		sgDrawBitmap++;
		
	}
	
	
	void OpenGLContext::SetBitmapData (const float *inPos, const float *inTex) {
		
		#ifndef LIME_FORCE_GLES2
		glVertexPointer (2, GL_FLOAT, 0, inPos);
		glTexCoordPointer (2, GL_FLOAT, 0, inTex);
		#endif
		
	}
	
	
	void OpenGLContext::SetColourArray (const int *inData) {
		
		#ifndef LIME_FORCE_GLES2
		if (inData) {
			
			mColourArrayEnabled = true;
			glEnableClientState (GL_COLOR_ARRAY);
			glColorPointer (4, GL_UNSIGNED_BYTE, 0, inData);
			
		} else if (mColourArrayEnabled) {
			
			mColourArrayEnabled = false;
			glDisableClientState (GL_COLOR_ARRAY);
			
		}
		#endif
		
	}
	
	
	void OpenGLContext::SetLineWidth (double inWidth) {
		
		if (inWidth != mLineWidth) {
			
			double w = inWidth;
			#ifndef LIME_FORCE_GLES2
			if (mQuality >= sqBest) {
				
				if (w > 1) {
					
					glDisable (GL_LINE_SMOOTH);
					
				} else {
					
					w = 1;
					if (inWidth == 0) {
						
						glDisable (GL_LINE_SMOOTH);
						
					} else {
						
						glEnable (GL_LINE_SMOOTH);
						
					}
					
				}
				
			}
			#endif
			
			mLineWidth = inWidth;
			glLineWidth (w);
			
			// TODO: Need replacement call for GLES2?
			#ifndef LIME_FORCE_GLES2
			if (mPointsToo)
				glPointSize (inWidth);
			#endif
			
		}
		
	}
	
	
	void OpenGLContext::SetModulatingTransform (const ColorTransform *inTransform) {
		
		#ifndef LIME_FORCE_GLES2
		if (inTransform) {
			if (mAlphaMode == amPremultiplied)
				glColor4f (inTransform->redMultiplier * inTransform->alphaMultiplier, inTransform->greenMultiplier * inTransform->alphaMultiplier, inTransform->blueMultiplier * inTransform->alphaMultiplier, inTransform->alphaMultiplier);
			else
				glColor4f (inTransform->redMultiplier, inTransform->greenMultiplier, inTransform->blueMultiplier, inTransform->alphaMultiplier);
		}
		#endif
		
	}
	
	
	void OpenGLContext::setOrtho (float x0,float x1, float y0, float y1) {
		
		#ifndef LIME_FORCE_GLES2
		
		glMatrixMode (GL_PROJECTION);
		glLoadIdentity ();
		
		#if defined (LIME_GLES)
		glOrthof (x0, x1, y0, y1, -1, 1);
		#else
		glOrtho (x0, x1, y0, y1, -1, 1);
		#endif
		
		glMatrixMode (GL_MODELVIEW);
		glLoadIdentity ();
		
		#endif
		
		mModelView = Matrix ();
		
	}
	
	
	void OpenGLContext::SetPositionData (const float *inData, bool inPerspective) {
		
		#ifndef LIME_FORCE_GLES2
		glVertexPointer (inPerspective ? 4 : 2, GL_FLOAT, 0, inData);
		#endif
		
	}
	
	
	void OpenGLContext::SetQuality (StageQuality inQ) {
		
		#ifndef LIME_FORCE_GLES2
		//inQ = sqMedium;
		if (inQ != mQuality) {
			
			mQuality = inQ;
			if (mQuality >= sqHigh) {
				
				if (mPointSmooth)
					glEnable (GL_POINT_SMOOTH);
				
			} else {
				
				glDisable (GL_POINT_SMOOTH);
				
			}
			
			if (mQuality >= sqBest)
				glEnable (GL_LINE_SMOOTH);
			else
				glDisable (GL_LINE_SMOOTH);
			mLineWidth = 99999;
			
		}
		#endif
		
	}
	
	
	void OpenGLContext::SetRadialGradient (bool inIsRadial, float inFocus) {};
	
	
	void OpenGLContext::SetSolidColour (unsigned int col) {
		
		#ifndef LIME_FORCE_GLES2
		float a = (float)((col >> 24) & 0xFF) * one_on_255;
		float c0 = (float)((col >> 16) & 0xFF) * one_on_255;
		float c1 = (float)((col >> 8) & 0xFF) * one_on_255;
		float c2 = (float)(col & 0xFF) * one_on_255;
		if (mAlphaMode == amPremultiplied)
			glColor4f (c0 * a, c1 * a,c2 * a, a);
		else
			glColor4f (c0, c1, c2, a);
		#endif
		
	}
	
	
	void OpenGLContext::SetTexture (Surface *inSurface, const float *inTexCoords) {
		
		#ifndef LIME_FORCE_GLES2
		if (!inSurface) {
			
			glDisable (GL_TEXTURE_2D);
			glDisableClientState (GL_TEXTURE_COORD_ARRAY);
			
		} else {
			
			glEnable (GL_TEXTURE_2D);
			inSurface->Bind (*this, 0);
			glEnableClientState (GL_TEXTURE_COORD_ARRAY);
			glTexCoordPointer (2, GL_FLOAT, 0, inTexCoords);
			
		}
		#endif
		
	}
	
	
	void OpenGLContext::SetViewport (const Rect &inRect) {

		if (inRect != mViewport) {
			
			setOrtho (inRect.x, inRect.x1 (), inRect.y1 (), inRect.y);
			mViewport = inRect;
			glViewport (inRect.x, mHeight - inRect.y1 (), inRect.w, inRect.h);
			
		}
		
	}
	
	
	void OpenGLContext::SetWindowSize (int inWidth, int inHeight) {
		
		mWidth = inWidth;
		mHeight = inHeight;
		
		#ifdef ANDROID
		//__android_log_print(ANDROID_LOG_ERROR, "lime", "SetWindowSize %d %d", inWidth, inHeight);
		#endif
		
	}
	
	
}
