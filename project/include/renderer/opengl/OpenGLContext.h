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
			
			void BeginBitmapRender (Surface *inSurface, uint32 inTint, bool inRepeat, bool inSmooth);
			void BeginRender (const Rect &inRect, bool inForHitTest);
			void Clear (uint32 inColour, const Rect *inRect);
			void CombineModelView (const Matrix &inModelView);
			Texture *CreateTexture (Surface *inSurface, unsigned int inFlags);
			void DestroyNativeTexture (void *inNativeTexture);
			void DestroyVbo (unsigned int inVbo);
			void EndBitmapRender ();
			void EndRender ();
			void Flip ();
			void Render (const RenderState &inState, const HardwareData &inData);
			void RenderBitmap (const Rect &inSrc, int inX, int inY);
			void RenderData (const HardwareData &inData, const ColorTransform *ctrans, const Trans4x4 &inTrans);
			void SetLineWidth (double inWidth);
			void setOrtho (float x0, float x1, float y0, float y1);
			void SetQuality (StageQuality inQ);
			void SetViewport (const Rect &inRect);
			void SetWindowSize (int inWidth, int inHeight);
			
			int Height () const { return mHeight; }
			int Width () const { return mWidth; }
			
			HardwareData mBitmapBuffer;
			Texture *mBitmapTexture;
			Trans4x4 mBitmapTrans;
			WinDC mDC;
			int mHeight;
			double mLineScaleH;
			double mLineScaleNormal;
			double mLineScaleV;
			double mLineWidth;
			Matrix mModelView;
			double mOffsetX;
			double mOffsetY;
			GLCtx mOGLCtx;
			GPUProg *mProg[PROG_COUNT];
			StageQuality mQuality;
			double mScaleX;
			double mScaleY;
			ThreadId mThreadId;
			Trans4x4 mTrans;
			Rect mViewport;
			int mWidth;
			QuickVec<GLuint> mZombieTextures;
			QuickVec<GLuint> mZombieVbos;
		
	};
	
	
	const double one_on_255 = 1.0 / 255.0;
	const double one_on_256 = 1.0 / 256.0;
	static GLuint sgOpenglType[] = { GL_TRIANGLE_FAN, GL_TRIANGLE_STRIP, GL_TRIANGLES, GL_LINE_STRIP, GL_POINTS, GL_LINES };
	
	
}


#endif
