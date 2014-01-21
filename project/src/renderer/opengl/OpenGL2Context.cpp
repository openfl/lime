#include "renderer/opengl/OpenGL2Context.h"


namespace lime {
	
	
	OpenGL2Context::OpenGL2Context (WinDC inDC, GLCtx inOGLCtx) : OpenGLContext (inDC, inOGLCtx) {
		
		mIsRadial = false;
		
		for (int i = 0; i < gpuSIZE; i++)
			mProg[i] = 0;
		
		for (int i = 0; i < 4; i++)
			for (int j = 0; j < 4; j++)
				mBitmapTrans[i][j] = mTrans[i][j] = (i == j);
		//mBitmapTrans[2][2] = 0.0;
		
	}
	
	
	OpenGL2Context::~OpenGL2Context () {
		
		for (int i = 0; i < gpuSIZE; i++)
			delete mProg[i];
		
	}
	
	
	void OpenGL2Context::CombineModelView (const Matrix &inModelView) {
		
		mTrans[0][0] = inModelView.m00 * mScaleX;
		mTrans[0][1] = inModelView.m01 * mScaleX;
		mTrans[0][2] = 0;
		mTrans[0][3] = inModelView.mtx * mScaleX + mOffsetX;
		
		mTrans[1][0] = inModelView.m10 * mScaleY;
		mTrans[1][1] = inModelView.m11 * mScaleY;
		mTrans[1][2] = 0;
		mTrans[1][3] = inModelView.mty * mScaleY + mOffsetY;
		
	}
	
	
	void OpenGL2Context::FinishBitmapRender () {
		
		// TODO: Need replacement call for GLES2
		//#ifndef LIME_FORCE_GLES2
		//glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		//#endif
		
	}
	
	
	void OpenGL2Context::FinishDrawing () {
		
		if (mCurrentProg)
			mCurrentProg->finishDrawing ();
		
	}
	
	
	void OpenGL2Context::OnBeginRender () {}
	
	
	void OpenGL2Context::PopBitmapMatrix () {}
	
	
	void OpenGL2Context::PrepareBitmapRender () {
		
		GPUProgID id = mBitmapSurface->BytesPP () == 1 ? gpuBitmapAlpha : gpuBitmap;
		if (!mProg[id])
			mProg[id] = GPUProg::create (id, mAlphaMode);
		mCurrentProg = mProg[id];
		if (!mCurrentProg)
			return;
		
		mCurrentProg->bind ();
		mCurrentProg->setTint (mTint);
		mBitmapSurface->Bind (*this, 0);
		mCurrentProg->setTransform (mBitmapTrans);
		// TODO: Need replacement call for GLES2
		//#ifndef LIME_FORCE_GLES2
		//glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		//#endif
		
	}
	
	
	bool OpenGL2Context::PrepareDrawing () {
		
		GPUProgID id = gpuNone;
		
		if (mTexCoords) {
			
			if (mIsRadial) {
				
				if (mRadialFocus != 0) {
					
					id = gpuRadialFocusGradient;
					
				} else {
					
					id = gpuRadialGradient;
					
				}
				
			} else if (mColourTransform && !mColourTransform->IsIdentity ()) {
				
				id = gpuTextureTransform;
				
			} else if (mColourArray) {
				
				id = gpuTextureColourArray;
				
			} else {
				
				id = gpuTexture;
				
			}
			
		} else {
			
			if (mColourArray) {
				
				if (mColourTransform && !mColourTransform->IsIdentity ()) {
					
					id = gpuColourTransform;
					
				} else {
					
					id = gpuColour;
					
				}
				
			} else {
				
				id = gpuSolid;
				
			}
			
		}

		if (id == gpuNone)
			return false;
		
		if (!mProg[id])
			mProg[id] = GPUProg::create (id, mAlphaMode);
		
		if (!mProg[id])
			return false;
		
		GPUProg *prog = mProg[id];
		mCurrentProg = prog;
		prog->bind ();
		
		prog->setPositionData (mPosition, mPositionPerspective);
		prog->setTransform (mTrans);
		
		if (mTexCoords) {
			
			prog->setTexCoordData (mTexCoords);
			mTextureSurface->Bind (*this, 0);
			
		}
		
		if (mColourArray)
			prog->setColourData (mColourArray);
		
		if (mColourTransform)
			prog->setColourTransform (mColourTransform);

		if (id == gpuRadialFocusGradient)
			prog->setGradientFocus (mRadialFocus);
		
		return true;
		
	}
	
	
	void OpenGL2Context::PushBitmapMatrix () {}
	
	
	void OpenGL2Context::SetBitmapData (const float *inPos, const float *inTex) {
		
		mCurrentProg->setPositionData (inPos, false);
		mCurrentProg->setTexCoordData (inTex);
		
	}
	
	
	void OpenGL2Context::SetColourArray (const int *inData) {
		
		mColourArray = inData;
		
	}
	
	
	void OpenGL2Context::SetModulatingTransform (const ColorTransform *inTransform) {
		
		mColourTransform = inTransform;
		
	}
	
	
	void OpenGL2Context::setOrtho (float x0, float x1, float y0, float y1) {
		
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
	
	
	void OpenGL2Context::SetPositionData (const float *inData,bool inPerspective) {
		
		mPosition = inData;
		mPositionPerspective = inPerspective;
		
	}
	
	
	void OpenGL2Context::SetRadialGradient (bool inIsRadial, float inFocus) {
		
		mIsRadial = inIsRadial;
		mRadialFocus = inFocus;
		
	}
	
	
	void OpenGL2Context::SetSolidColour (unsigned int col) {
		
		if (mCurrentProg)
			mCurrentProg->setTint (col);
		
	}
	
	
	void OpenGL2Context::SetTexture (Surface *inSurface, const float *inTexCoords) {
		
		mTextureSurface = inSurface;
		mTexCoords = inTexCoords;
		
	}
	
	
}
