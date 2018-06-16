#ifndef LIME_GRAPHICS_IMAGE_H
#define LIME_GRAPHICS_IMAGE_H


#include <graphics/ImageBuffer.h>
#include <math/Rectangle.h>
#include <system/CFFI.h>


namespace lime {
	
	
	struct Image {
		
		hl_type* t;
		ImageBuffer* buffer;
		bool dirty;
		int height;
		int offsetX;
		int offsetY;
		HL_Rectangle* rect;
		/*ImageType*/ int type;
		int version;
		int width;
		double x;
		double y;
		
		Image (value image);
		~Image ();
		
	};
	
	
}


#endif