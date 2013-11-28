#ifndef RENDERER_AUTO_SURFACE_RENDER_H
#define RENDERER_AUTO_SURFACE_RENDER_H


#include "renderer/common/Surface.h"


namespace lime {
	
	
	class AutoSurfaceRender {
		
		public:
			
			AutoSurfaceRender (Surface *inSurface) : mSurface (inSurface), mTarget (inSurface->BeginRender (Rect (inSurface->Width (), inSurface->Height ()), false)) {}
			AutoSurfaceRender (Surface *inSurface, const Rect &inRect) : mSurface (inSurface), mTarget (inSurface->BeginRender (inRect, false)) {}
			~AutoSurfaceRender () { mSurface->EndRender (); }
			
			const RenderTarget &Target () { return mTarget; }
		
		private:
			
			Surface *mSurface;
			RenderTarget mTarget;
		
	};
	
	
}


#endif
