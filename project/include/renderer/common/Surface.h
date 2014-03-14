#ifndef RENDERER_SURFACE_H
#define RENDERER_SURFACE_H


#include <Object.h>
#include <Display.h>
#include <ByteArray.h>
#include "renderer/common/Texture.h"
#include "renderer/common/HardwareContext.h"
#include <Hardware.h>


namespace lime {
	
	
	void HintColourOrder (bool inRedFirst);
	
	enum {
		
		SURF_FLAGS_NOT_REPEAT_IF_NON_PO2 = 0x0001,
		SURF_FLAGS_USE_PREMULTIPLIED_ALPHA  = 0x0002,
		SURF_FLAGS_HAS_PREMULTIPLIED_ALPHA  = 0x0004
		
	};
	
	
	class Surface : public Object {
		
		public:
			
			#ifdef LIME_PREMULTIPLIED_ALPHA
			Surface () : mTexture (0), mVersion (0), mFlags (SURF_FLAGS_NOT_REPEAT_IF_NON_PO2 | SURF_FLAGS_USE_PREMULTIPLIED_ALPHA), mAllowTrans (true) {}; // Non-PO2 will generate dodgy repeating anyhow...
			#else
			Surface () : mTexture (0), mVersion (0), mFlags (SURF_FLAGS_NOT_REPEAT_IF_NON_PO2), mAllowTrans (true) {}; // Non-PO2 will generate dodgy repeating anyhow...
			#endif
			
			virtual RenderTarget BeginRender (const Rect &inRect, bool inForHitTest = false) = 0;
			virtual void BlitChannel (const RenderTarget &outTarget, const Rect &inSrcRect, int inPosX, int inPosY, int inSrcChannel, int inDestChannel) const = 0;
			virtual void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY, BlendMode inBlend, const BitmapCache *inMask, uint32 inTint=0xffffff ) const = 0;
			virtual void Clear (uint32 inColour, const Rect *inRect = 0) = 0;
			virtual void EndRender () = 0;
			virtual PixelFormat Format () const = 0;
			virtual const uint8 *GetBase () const = 0;
			virtual int GetStride () const = 0;
			virtual int Height () const = 0;
			virtual int Width () const = 0;
			
			virtual void applyFilter (Surface *inSrc, const Rect &inRect, ImagePoint inOffset, Filter *inFilter) {}
			virtual void colorTransform (const Rect &inRect, ColorTransform &inTransform) {}
			virtual Surface *clone () { return 0; }
			virtual void createHardwareSurface () {}
			virtual void destroyHardwareSurface () {}
			virtual void dispose () {}
			virtual void dumpBits () { /*printf("Dumping bits from Surface\n");*/  }
			virtual bool GetAllowTrans () const { return mAllowTrans; }
			virtual void getColorBoundsRect (int inMask, int inCol, bool inFind, Rect &outRect) { outRect = Rect (0, 0, Width (), Height ()); }
			virtual unsigned int GetFlags () const { return mFlags; }
			virtual uint32 getPixel (int inX, int inY) { return 0; }
			virtual void getPixels (const Rect &inRect, uint32 *outPixels, bool inIgnoreOrder = false, bool inLittleEndian = false) {}
			virtual int GPUFormat () const { return Format (); }
			virtual void multiplyAlpha () {}
			virtual void noise (unsigned int randomSeed, unsigned int low, unsigned int high, int channelOptions, bool grayScale) {}
			virtual void SetAllowTrans (bool inAllowTrans) { mAllowTrans = inAllowTrans; }
			virtual void SetFlags (unsigned int inFlags) { mFlags = inFlags; }
			virtual void setGPUFormat (PixelFormat pf) {}
			virtual void setPixel (int inX, int inY, uint32 inRGBA, bool inAlphaToo = false) {}
			virtual void setPixels (const Rect &inRect, const uint32 *intPixels, bool inIgnoreOrder = false, bool inLittleEndian = false) {}
			virtual void scroll (int inDX, int inDY) {}
			virtual void StretchTo (const RenderTarget &outTarget, const Rect &inSrcRect, const DRect &inDestRect) const = 0;
			virtual void unmultiplyAlpha () {}
			virtual void Zero () { Clear (0); }
			
			static Surface *Load (const OSChar *inFilename); // Implementation depends on platform.
			static Surface *LoadFromBytes (const uint8 *inBytes, int inLen);
			
			void Bind (HardwareContext &inHardware, int inSlot = 0);
			int BytesPP () const { return Format () == pfAlpha ? 1 : 4; }
			bool Encode (lime::ByteArray *outBytes, bool inPNG, double inQuality);
			Texture *GetOrCreateTexture (HardwareContext &inHardware);
			Texture *GetTexture () { return mTexture; }
			Surface *IncRef () { mRefCount++; return this; }
			const uint8 *Row (int inY) const { return GetBase () + GetStride () * inY; }
			int Version () const { return mVersion; }
		
		protected:
			
			virtual	~Surface ();
			
			bool mAllowTrans;
			unsigned int mFlags;
			Texture *mTexture;
			mutable int	mVersion;
		
	};
	
	
}


#endif
