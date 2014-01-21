#ifndef RENDERER_OPENGL2_CONTEXT_H
#define RENDERER_OPENGL2_CONTEXT_H


#include "OpenGLContext.h"


namespace lime {
	
	
	class OpenGL2Context : public OpenGLContext {
		
		public:
			
			OpenGL2Context (WinDC inDC, GLCtx inOGLCtx);
			~OpenGL2Context ();
			
			virtual void CombineModelView (const Matrix &inModelView);
			virtual void FinishBitmapRender ();
			virtual void FinishDrawing ();
			virtual void OnBeginRender ();
			virtual void PopBitmapMatrix ();
			virtual void PrepareBitmapRender ();
			virtual bool PrepareDrawing ();
			virtual void PushBitmapMatrix ();
			virtual void SetBitmapData (const float *inPos, const float *inTex);
			virtual void SetColourArray (const int *inData);
			virtual void SetModulatingTransform (const ColorTransform *inTransform);
			virtual void setOrtho (float x0, float x1, float y0, float y1);
			virtual void SetPositionData (const float *inData, bool inPerspective);
			virtual void SetRadialGradient (bool inIsRadial, float inFocus);
			virtual void SetSolidColour (unsigned int col);
			virtual void SetTexture (Surface *inSurface, const float *inTexCoords);
			
			Trans4x4 mBitmapTrans;
			const int *mColourArray;
			GPUProg *mCurrentProg;
			const ColorTransform *mColourTransform;
			bool mIsRadial;
			double mOffsetX;
			double mOffsetY;
			const float *mPosition;
			bool mPositionPerspective;
			GPUProg *mProg[gpuSIZE];
			float mRadialFocus;
			double mScaleX;
			double mScaleY;
			const float *mTexCoords;
			Surface *mTextureSurface;
			Trans4x4 mTrans;
		
	};
	
	
}


#endif
