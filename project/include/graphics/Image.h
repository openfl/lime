#ifndef LIME_GRAPHICS_IMAGE_H
#define LIME_GRAPHICS_IMAGE_H


#include <hl.h>
#include <hx/CFFI.h>
#include <graphics/ImageBuffer.h>
#include <math/Rectangle.h>


namespace lime {
	
	
	struct HL_Image {
		
		hl_type* t;
		HL_ImageBuffer* buffer;
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
		
	};
	
	
	class Image {
		
		
		public:
			
			Image ();
			Image (value image);
			Image (HL_Image* image);
			~Image ();
			
			ImageBuffer *buffer;
			int height;
			int offsetX;
			int offsetY;
			int width;
		
		private:
			
			value mValue;
		
		
	};
	
	
}


#endif