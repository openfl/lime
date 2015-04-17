#ifndef LIME_GRAPHICS_IMAGE_H
#define LIME_GRAPHICS_IMAGE_H


#include <hx/CFFI.h>
#include <graphics/ImageBuffer.h>
#include <utils/ByteArray.h>


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
			bool transparent;
			int width;
		
		private:
			
			value mValue;
		
		
	};
	
	
}


#endif