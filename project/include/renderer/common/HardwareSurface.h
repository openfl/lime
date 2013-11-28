#ifndef RENDERER_HARDWARE_SURFACE_H
#define RENDERER_HARDWARE_SURFACE_H


#include "renderer/common/Surface.h"
#include "renderer/common/HardwareContext.h"


namespace lime {
	
	
	class HardwareSurface : public Surface {
		
		public:
			
			HardwareSurface (HardwareContext *inContext);
			
			RenderTarget BeginRender (const Rect &inRect, bool inForHitTest) { mHardware->BeginRender (inRect, inForHitTest); return RenderTarget (inRect, mHardware); }
			void BlitTo (const RenderTarget &outTarget, const Rect &inSrcRect, int inPosX, int inPosY, BlendMode inBlend, const BitmapCache *inMask, uint32 inTint) const {}
			void BlitChannel (const RenderTarget &outTarget, const Rect &inSrcRect, int inPosX, int inPosY, int inSrcChannel, int inDestChannel) const {}
			void Clear (uint32 inColour, const Rect *inRect = 0) { mHardware->Clear (inColour, inRect); }
			void EndRender () { mHardware->EndRender (); }
			PixelFormat Format () const { return pfHardware; }
			AlphaMode GetAlphaMode () const { return mAlphaMode; }
			const uint8 *GetBase () const { return 0; }
			int GetStride () const { return 0; }
			int Height () const { return mHardware->Height (); }
			void StretchTo (const RenderTarget &outTarget, const Rect &inSrcRect, const DRect &inDestRect) const {}
			int Width () const { return mHardware->Width (); }
			
			Surface *clone ();
			//void getPixels (const Rect &inRect, uint32 *outPixels, bool inIgnoreOrder = false);
			//void setPixels (const Rect &inRect, const uint32 *intPixels, bool inIgnoreOrder = false);
		
		protected:
			
			~HardwareSurface ();
		
		private:
			
			AlphaMode mAlphaMode;
			HardwareContext *mHardware;
		
	};
	
	
}


#endif
