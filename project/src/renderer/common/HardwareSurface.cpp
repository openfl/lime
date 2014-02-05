#include "renderer/common/HardwareSurface.h"


namespace lime {
	
	
	HardwareSurface::HardwareSurface (HardwareContext *inContext) {
		
		mHardware = inContext;
		mHardware->IncRef ();
		
	}
	
	
	HardwareSurface::~HardwareSurface () {
		
		mHardware->DecRef ();
		
	}
	
	
	Surface *HardwareSurface::clone () {
		
		// This is not really a clone...
		Surface *copy = new HardwareSurface (mHardware);
		copy->IncRef ();
		return copy;
		
	}
	
	
	/*void HardwareSurface::getPixels (const Rect &inRect, uint32 *outPixels, bool inIgnoreOrder) {
		
		memset (outPixels, 0, Width () * Height () * 4);
		
	}
	
	
	void HardwareSurface::setPixels (const Rect &inRect, const uint32 *outPixels, bool inIgnoreOrder) {}*/
	
	
}
