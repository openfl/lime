#ifndef LIME_GRAPHICS_IMAGE_H
#define LIME_GRAPHICS_IMAGE_H


#include <hx/CFFI.h>
#include <graphics/ImageBuffer.h>


namespace lime {
	
	
	class Image {
		
		
		public:
			
			Image ();
			Image (value image);
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