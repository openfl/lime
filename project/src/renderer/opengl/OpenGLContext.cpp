#include "renderer/opengl/OpenGLContext.h"


int sgDrawCount = 0;
int sgDrawBitmap = 0;


namespace lime {
	
	
	OpenGLContext::OpenGLContext (WinDC inDC, GLCtx inOGLCtx) {
		
		HardwareContext::current = this;
		mDC = inDC;
		mOGLCtx = inOGLCtx;
		mWidth = 0;
		mHeight = 0;
		mLineWidth = -1;
		mBitmapTexture = 0;
		mLineScaleNormal = -1;
		mLineScaleV = -1;
		mLineScaleH = -1;
		mThreadId = GetThreadId ();
		
		#if defined(LIME_GLES)
		mQuality = sqLow;
		#else
		mQuality = sqBest;
		#endif
		
		for (int i = 0; i < PROG_COUNT; i++) {
			
			mProg[i] = 0;
			
		}
		
		for (int i = 0; i < 4; i++) {
			
			for (int j = 0; j < 4; j++) {
				
				mBitmapTrans[i][j] = mTrans[i][j] = (i == j);
				
			}
			
		}
		
		mBitmapBuffer.mElements.resize (1);
		DrawElement &e = mBitmapBuffer.mElements[0];
		memset (&e, 0, sizeof (DrawElement));
		e.mCount = 0;
		e.mFlags = DRAW_HAS_TEX;
		e.mPrimType = ptTriangles;
		e.mVertexOffset = 0;
		e.mColour = 0xff000000;
		e.mTexOffset = sizeof (float) * 2;
		e.mStride = sizeof (float) * 4;
		
	}
	
	
	OpenGLContext::~OpenGLContext () {
		
		for (int i = 0; i < PROG_COUNT; i++) {
			
			delete mProg[i];
			
		}
		
	}
	
	
	void OpenGLContext::BeginBitmapRender (Surface *inSurface, uint32 inTint, bool inRepeat, bool inSmooth) {
		
		mBitmapBuffer.mArray.resize (0);
		mBitmapBuffer.mRendersWithoutVbo = -999;
		DrawElement &e = mBitmapBuffer.mElements[0];
		e.mCount = 0;
		
		e.mColour = inTint;
		if (e.mSurface) {
			
			e.mSurface->DecRef ();
		}
		
		e.mSurface = inSurface;
		e.mSurface->IncRef ();
		e.mFlags = (e.mFlags & ~(DRAW_BMP_REPEAT|DRAW_BMP_SMOOTH));
		
		if (inRepeat) {
			
			e.mFlags |= DRAW_BMP_REPEAT;
			
		}
		
		if (inSmooth) {
			
			e.mFlags |= DRAW_BMP_SMOOTH;
			
		}
		
		mBitmapTexture = inSurface->GetOrCreateTexture (*this);
		
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
			
			if (mZombieVbos.size ()) {
				
				glDeleteTextures (mZombieVbos.size (), &mZombieVbos[0]);
				mZombieVbos.resize (0);
				
			}
			
			// Force dirty
			mViewport.w = -1;
			SetViewport (inRect);
			
			glEnable (GL_BLEND);
			
			#ifdef WEBOS
			glColorMask (GL_TRUE, GL_TRUE, GL_TRUE, GL_FALSE);
			#endif
			
			mLineWidth = 99999;
			
			// printf("DrawArrays: %d, DrawBitmaps:%d  Buffers:%d\n", sgDrawCount, sgDrawBitmap, sgBufferCount );
			sgDrawCount = 0;
			sgDrawBitmap = 0;
			
		}
		
	}
	
	
	void OpenGLContext::Clear (uint32 inColour, const Rect *inRect) {
		
		Rect r = inRect ? *inRect : Rect (mWidth, mHeight);
	  	
		glViewport (r.x, mHeight - r.y1 (), r.w, r.h);
		
		float alpha = ((inColour >> 24) & 0xFF) / 255.0;
		float red = ((inColour >> 16) & 0xFF) / 255.0;
		float green = ((inColour >> 8) & 0xFF) / 255.0;
		float blue = (inColour & 0xFF) / 255.0;
		red *= alpha;
		green *= alpha;
		blue *= alpha;
		
		if (r == Rect (mWidth, mHeight)) {
			
			glClearColor (red, green, blue, alpha );
			glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
			
		} else {
			
			//printf(" - partial clear\n");
			
		}
		
		if (r != mViewport) {
			
			glViewport (mViewport.x, mHeight - mViewport.y1 (), mViewport.w, mViewport.h);
			
		}
		
	}
	
	
	void OpenGLContext::CombineModelView (const Matrix &inModelView) {
		
		mTrans[0][0] = inModelView.m00 * mScaleX;
		mTrans[0][1] = inModelView.m01 * mScaleX;
		mTrans[0][2] = 0;
		mTrans[0][3] = inModelView.mtx * mScaleX + mOffsetX;
		
		mTrans[1][0] = inModelView.m10 * mScaleY;
		mTrans[1][1] = inModelView.m11 * mScaleY;
		mTrans[1][2] = 0;
		mTrans[1][3] = inModelView.mty * mScaleY + mOffsetY;
		
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


	void OpenGLContext::DestroyVbo (unsigned int inVbo) {
		
		if (!IsMainThread ()) {
			
			mZombieVbos.push_back (inVbo);
			
		} else {
			
			glDeleteBuffers (1, &inVbo);
			
		}
		
	}
	
	
	void OpenGLContext::EndBitmapRender () {
		
		DrawElement &e = mBitmapBuffer.mElements[0];
		
		if (e.mCount) {
			
			RenderData (mBitmapBuffer, 0, mBitmapTrans);
			e.mCount = 0;
			
		}
		
		if (e.mSurface) {
			
			e.mSurface->DecRef ();
			e.mSurface = 0;
			
		}
		
		mBitmapBuffer.mArray.resize (0);
		mBitmapTexture = 0;
		
	}
	
	
	void OpenGLContext::EndRender () {
		
		
		
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
	
	
	void OpenGLContext::Render (const RenderState &inState, const HardwareData &inData) {
		
		if (!inData.mArray.size ()) {
			
			return;
			
		}
		
		SetViewport (inState.mClipRect);
		
		if (mModelView != *inState.mTransform.mMatrix) {
			
			mModelView = *inState.mTransform.mMatrix;
			CombineModelView (mModelView);
			mLineScaleV = -1;
			mLineScaleH = -1;
			mLineScaleNormal = -1;
			
		}
		
		const ColorTransform *ctrans = inState.mColourTransform;
		
		if (ctrans && ctrans->IsIdentity ()) {
			
			ctrans = 0;
			
		}
		
		RenderData (inData, ctrans, mTrans);
		
	}
	
	
	void OpenGLContext::RenderBitmap (const Rect &inSrc, int inX, int inY) {
		
		DrawElement &e = mBitmapBuffer.mElements[0];
		mBitmapBuffer.mArray.resize ((e.mCount + 6) * e.mStride);
		UserPoint *p = (UserPoint *)&mBitmapBuffer.mArray[e.mCount * e.mStride];
		e.mCount += 6;
		
		UserPoint corners[4];
		UserPoint tex[4];
		
		for (int i = 0; i < 4; i++) {
			
			corners[i] = UserPoint (inX + ((i & 1) ? inSrc.w : 0), inY + ((i > 1) ? inSrc.h : 0)); 
			tex[i] = mBitmapTexture->PixelToTex (UserPoint (inSrc.x + ((i & 1) ? inSrc.w : 0), inSrc.y + ((i > 1) ? inSrc.h : 0)));
			 
		}
		
		*p++ = corners[0];
		*p++ = tex[0];
		*p++ = corners[1];
		*p++ = tex[1];
		*p++ = corners[2];
		*p++ = tex[2];
		
		*p++ = corners[1];
		*p++ = tex[1];
		*p++ = corners[2];
		*p++ = tex[2];
		*p++ = corners[3];
		*p++ = tex[3];
		
	}
	
	
	void OpenGLContext::RenderData (const HardwareData &inData, const ColorTransform *ctrans, const Trans4x4 &inTrans) {
		
		const uint8 *data = 0;
		
		if (inData.mVertexBo) {
			
			glBindBuffer (GL_ARRAY_BUFFER, inData.mVertexBo);
			
		} else {
			
			data = &inData.mArray[0];
			inData.mRendersWithoutVbo++;
			
			if (false && inData.mRendersWithoutVbo > 4) {
				
				glGenBuffers (1, &inData.mVertexBo);
				inData.mVboOwner = this;
				IncRef ();
				glBindBuffer (GL_ARRAY_BUFFER, inData.mVertexBo);
				// printf ("VBO DATA %d\n", inData.mArray.size ());
				glBufferData (GL_ARRAY_BUFFER, inData.mArray.size (), data, GL_STATIC_DRAW);
				data = 0;
				
			}
			
		}
		
		GPUProg *lastProg = 0;
 		
		for (int e = 0; e < inData.mElements.size (); e++) {
			
			const DrawElement &element = inData.mElements[e];
			int n = element.mCount;
			
			if (!n) {
				
				continue;
				
			}
			
			int progId = 0;
			bool premAlpha = false;
			
			if ((element.mFlags & DRAW_HAS_TEX) && element.mSurface) {
				
				if (element.mSurface->GetFlags () & SURF_FLAGS_USE_PREMULTIPLIED_ALPHA) {
					
					premAlpha = true;
					
				}
				
				progId |= PROG_TEXTURE;
				
				if (element.mSurface->BytesPP () == 1) {
					
					progId |= PROG_ALPHA_TEXTURE;
					
				}
				
			}
			
			if (element.mFlags & DRAW_HAS_COLOUR) {
				
				progId |= PROG_COLOUR_PER_VERTEX;
				
			}
			
			if (element.mFlags & DRAW_HAS_NORMAL) {
				
				progId |= PROG_NORMAL_DATA;
				
			}
			
			if (element.mFlags & DRAW_RADIAL) {
				
				progId |= PROG_RADIAL;
				if (element.mRadialPos != 0) {
					
					progId |= PROG_RADIAL_FOCUS;
					
				}
				
			}
			
			if (ctrans || element.mColour != 0xFFFFFFFF) {
				
				progId |= PROG_TINT;
				if (ctrans && ctrans->HasOffset ())
					progId |= PROG_COLOUR_OFFSET;
				
			}
			
			bool persp = element.mFlags & DRAW_HAS_PERSPECTIVE;
			GPUProg *prog = mProg[progId];
			
			if (!prog) {
				
				mProg[progId] = prog = GPUProg::create (progId);
				
			}
			
			if (!prog) {
				
				continue;
				
			}
			
						
			switch (element.mBlendMode) {
				
				case bmAdd:
					
					glBlendFunc (GL_SRC_ALPHA, GL_ONE);
					break;
				
				case bmMultiply:
					
					glBlendFunc (GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
					break;
				
				case bmScreen:
					
					glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_COLOR);
					break;
				
				default:
					
					glBlendFunc (premAlpha ? GL_ONE : GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
					break;
				
			}
			
			if (prog != lastProg) {
				
				if (lastProg) {
					
					lastProg->disableSlots ();
					
				}
				
				prog->bind ();
				prog->setTransform (inTrans);
				lastProg = prog;
				
			}
			
			int stride = element.mStride;
			if (prog->vertexSlot >= 0) {
				
				glVertexAttribPointer (prog->vertexSlot, persp ? 4 : 2 , GL_FLOAT, GL_FALSE, stride, data + element.mVertexOffset);
				glEnableVertexAttribArray (prog->vertexSlot);
				
			}
			
			if (prog->textureSlot >= 0) {
				
				glVertexAttribPointer (prog->textureSlot,  2 , GL_FLOAT, GL_FALSE, stride, data + element.mTexOffset);
				glEnableVertexAttribArray (prog->textureSlot);
				
				if (element.mSurface) {
					
					Texture *boundTexture = element.mSurface->GetOrCreateTexture (*this);
					element.mSurface->Bind (*this, 0);
					boundTexture->BindFlags (element.mFlags & DRAW_BMP_REPEAT, element.mFlags & DRAW_BMP_SMOOTH);
					
				}
				
			}
			
			if (prog->colourSlot >= 0) {
				
				glVertexAttribPointer (prog->colourSlot, 4, GL_UNSIGNED_BYTE, GL_TRUE, stride, data + element.mColourOffset);
				glEnableVertexAttribArray (prog->colourSlot);
				
			}
			
			if (prog->normalSlot >= 0) {
				
				glVertexAttribPointer (prog->normalSlot, 2, GL_FLOAT, GL_FALSE, stride, data + element.mNormalOffset);
				glEnableVertexAttribArray (prog->normalSlot);
				
			}
			
			if (element.mFlags & DRAW_RADIAL) {
				
				prog->setGradientFocus (element.mRadialPos * one_on_256);
				
			}
			
			if (progId & (PROG_TINT | PROG_COLOUR_OFFSET)) {
				
				prog->setColourTransform (ctrans, element.mColour);
				
			}
			
			if ((element.mPrimType == ptLineStrip || element.mPrimType == ptPoints || element.mPrimType == ptLines) && element.mCount > 1) {
				
				if (element.mWidth < 0) {
					
					SetLineWidth (1.0);
					
				} else if (element.mWidth == 0) {
					
					SetLineWidth (0.0);
					
				} else {
					
					switch (element.mScaleMode) {
						
						case ssmNone: SetLineWidth (element.mWidth); break;
							
						case ssmNormal:
						case ssmOpenGL:
							
							if (mLineScaleNormal < 0) {
								
								mLineScaleNormal = sqrt (0.5 * ((mModelView.m00 * mModelView.m00) + (mModelView.m01 * mModelView.m01) + (mModelView.m10 * mModelView.m10) + (mModelView.m11 * mModelView.m11)));
								
							}
							
							SetLineWidth (element.mWidth * mLineScaleNormal);
							break;
						
						case ssmVertical:
							
							if (mLineScaleV < 0) {
								
								mLineScaleV = sqrt ((mModelView.m00 * mModelView.m00) + (mModelView.m01 * mModelView.m01));
								
							}
							
							SetLineWidth (element.mWidth * mLineScaleV);
							break;
						
						case ssmHorizontal:
							
							if (mLineScaleH<0) {
								
								mLineScaleH = sqrt ((mModelView.m10 * mModelView.m10) + (mModelView.m11 * mModelView.m11));
								
							}
							
							SetLineWidth (element.mWidth * mLineScaleH);
							break;
						
					}
					
				}
				
			}
				
			//printf("glDrawArrays %d : %d x %d\n", element.mPrimType, element.mFirst, element.mCount );
			
			sgDrawCount++;
			glDrawArrays (sgOpenglType[element.mPrimType], 0, element.mCount);
			
		}
		
		if (lastProg) {
			
			lastProg->disableSlots ();
			
		}
		
		if (inData.mVertexBo) {
			
			glBindBuffer (GL_ARRAY_BUFFER, 0);
			
		}
		
	}
	
	
	inline void OpenGLContext::SetLineWidth (double inWidth) {
		
		if (inWidth != mLineWidth) {
			
			// TODO mQuality -> tessellate_lines/tessellate_lines_aa
			mLineWidth = inWidth;
			glLineWidth (inWidth);
			
		}
		
	}
	
	
	void OpenGLContext::setOrtho (float x0, float x1, float y0, float y1) {
		
		mScaleX = 2.0 / (x1 - x0);
		mScaleY = 2.0 / (y1 - y0);
		mOffsetX = (x0 + x1) / (x0 - x1);
		mOffsetY = (y0 + y1) / (y0 - y1);
		mModelView = Matrix ();
		
		mBitmapTrans[0][0] = mScaleX;
		mBitmapTrans[0][3] = mOffsetX;
		mBitmapTrans[1][1] = mScaleY;
		mBitmapTrans[1][3] = mOffsetY;
		
		CombineModelView (mModelView);
		
	} 
	
	
	void OpenGLContext::SetQuality (StageQuality inQ) {
		
		if (inQ != mQuality) {
			
			mQuality = inQ;
			mLineWidth = 99999;
			
		}
		
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
		//__android_log_print(ANDROID_LOG_ERROR, "Lime", "SetWindowSize %d %d", inWidth, inHeight);
		#endif
		
	}
	
		
}
