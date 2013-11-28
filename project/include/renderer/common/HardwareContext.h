#ifndef RENDERER_HARDWARE_CONTEXT_H
#define RENDERER_HARDWARE_CONTEXT_H


#include <Object.h>
#include <Graphics.h>


namespace lime {
	
	
	class HardwareContext : public Object {
		
		public:
			
			static HardwareContext *CreateDirectFB(void *inDFB, void *inSurface);
			static HardwareContext *CreateDX11(void *inDevice, void *inContext);
			static HardwareContext *CreateOpenGL(void *inWindow, void *inGLCtx, bool shaders);
			static HardwareContext *current;
			
			virtual void BeginBitmapRender (Surface *inSurface, uint32 inTint = 0, bool inRepeat = true, bool inSmooth = true) = 0;
			virtual void BeginRender (const Rect &inRect, bool inForHitTest) = 0;
			virtual void Clear (uint32 inColour, const Rect *inRect = 0) = 0;
			virtual class Texture *CreateTexture (class Surface *inSurface, unsigned int inFlags) = 0;
			virtual void DestroyNativeTexture (void *inNativeTexture) = 0;
			virtual void EndBitmapRender () = 0;
			virtual void EndRender () = 0;
			virtual void Flip () = 0;
			virtual int Height () const = 0;
			virtual bool Hits (const RenderState &inState, const HardwareCalls &inCalls);
			virtual void Render (const RenderState &inState, const HardwareCalls &inCalls) = 0;
			virtual void RenderBitmap (const Rect &inSrc, int inX, int inY) = 0;
			virtual void SetQuality (StageQuality inQuality) = 0;
			virtual void SetViewport (const Rect &inRect) = 0;
			virtual void SetWindowSize (int inWidth, int inHeight) = 0;
			virtual int Width () const = 0;
		
	};
	
	
};


#endif