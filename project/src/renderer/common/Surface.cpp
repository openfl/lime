#include "renderer/common/Surface.h"


namespace lime {
	
	
	int gTextureContextVersion = 1;
	bool sgColourOrderSet = false;
	
	
	// 32 bit colours will either be
	//
	// 0xAARRGGBB  (argb = format used when "int" is passes)
	// 0xAABBGGRR  (b-r "swapped" - like windows bitmaps )
	//
	// And the ARGB structure is { uint8 c0,c1,c2,alpha }
	// In little-endian land, this is 0x alpha c2 c1 c0,
	//  "gC0IsRed" then means red is the LSB, ie "abgr" format.

	#ifdef IPHONE
	bool gC0IsRed = true;
	#else
	bool gC0IsRed = true;
	#endif

	void HintColourOrder (bool inRedFirst) {
		
		if (!sgColourOrderSet) {
			
			sgColourOrderSet = true;
			gC0IsRed = inRedFirst;
			
		}
		
	}
	
	
	Surface::~Surface () {
		
		delete mTexture;
		
	}
	
	
	void Surface::Bind (HardwareContext &inHardware, int inSlot) {
		
		if (mTexture && !mTexture->IsCurrentVersion ()) {
			
			delete mTexture;
			mTexture = 0;
			
		}
		
		if (!mTexture)
			mTexture = inHardware.CreateTexture (this, mFlags);
		
		mTexture->Bind (this, inSlot);
		
	}
	
	
	Texture *Surface::GetOrCreateTexture (HardwareContext &inHardware) {
		
		if (mTexture && !mTexture->IsCurrentVersion ()) {
			
			delete mTexture;
			mTexture = 0;
			
		}
		
		if (!mTexture)
			mTexture = inHardware.CreateTexture (this, mFlags);
		
		return mTexture;
		
	}
	
	
}
