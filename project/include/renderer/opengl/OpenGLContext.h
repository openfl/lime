#ifndef RENDERER_OPENGL_CONTEXT_H
#define RENDERER_OPENGL_CONTEXT_H


#include <LimeThread.h>
#include "renderer/opengl/OGL.h"
#include "renderer/common/HardwareContext.h"


namespace lime {
	
	
	class OpenGLContext : public HardwareContext {
		
		public:
			
			OpenGLContext (WinDC inDC, GLCtx inOGLCtx);
			~OpenGLContext ();
			
			virtual void CombineModelView (const Matrix &inModelView);
			virtual void FinishDrawing ();
			virtual void FinishBitmapRender ();
			virtual void OnBeginRender ();
			virtual void PopBitmapMatrix ();
			virtual void PrepareBitmapRender ();
			virtual bool PrepareDrawing ();
			virtual void PushBitmapMatrix ();
			virtual void SetBitmapData (const float *inPos, const float *inTex);
			virtual void SetColourArray (const int *inData);
			virtual void SetModulatingTransform (const ColorTransform *inTransform);
			virtual void setOrtho (float x0,float x1, float y0, float y1);
			virtual void SetPositionData (const float *inData, bool inPerspective);
			virtual void SetRadialGradient (bool inIsRadial, float inFocus);
			virtual void SetSolidColour (unsigned int col);
			virtual void SetTexture (Surface *inSurface, const float *inTexCoords);
			
			void BeginBitmapRender (Surface *inSurface, uint32 inTint, bool inRepeat, bool inSmooth);
			void BeginRender (const Rect &inRect, bool inForHitTest);
			void Clear (uint32 inColour, const Rect *inRect);
			Texture *CreateTexture (Surface *inSurface, unsigned int inFlags);
			void DestroyNativeTexture (void *inNativeTexture);
			void EndBitmapRender ();
			void EndRender ();
			void Flip ();
			void Render (const RenderState &inState, const HardwareCalls &inCalls);
			void RenderBitmap (const Rect &inSrc, int inX, int inY);
			void SetLineWidth (double inWidth);
			void SetQuality (StageQuality inQ);
			void SetViewport (const Rect &inRect);
			void SetWindowSize (int inWidth, int inHeight);
			
			int Height () const { return mHeight; }
			int Width () const { return mWidth; }
			
			AlphaMode mAlphaMode;
			Surface *mBitmapSurface;
			Texture *mBitmapTexture;
			bool mColourArrayEnabled;
			WinDC mDC;
			int mHeight;
			double mLineScaleH;
			double mLineScaleNormal;
			double mLineScaleV;
			double mLineWidth;
			Matrix mModelView;
			GLCtx mOGLCtx;
			bool mPointSmooth;
			bool mPointsToo;
			StageQuality mQuality;
			ThreadId mThreadId;
			uint32 mTint;
			bool mUsingBitmapMatrix;
			Rect mViewport;
			int mWidth;
			QuickVec<GLuint> mZombieTextures;
			
	};
	
	
	const double one_on_255 = 1.0 / 255.0;
	static GLuint sgOpenglType[] = { GL_TRIANGLE_FAN, GL_TRIANGLE_STRIP, GL_TRIANGLES, GL_LINE_STRIP, GL_POINTS, GL_LINES };
	
	
}


#endif
