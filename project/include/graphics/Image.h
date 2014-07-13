#ifndef LIME_GRAPHICS_IMAGE_H
#define LIME_GRAPHICS_IMAGE_H


#include <hx/CFFI.h>
#include <utils/ByteArray.h>


namespace lime {
	
	
	class Image {
		
		
		public:
			
			Image ();
			~Image ();
			
			void Resize (int width, int height, int bpp = 4);
			void Blit (const unsigned char *data, int x, int y, int width, int height);
			value Value ();
			
			int width;
			int height;
			int bpp; // bytes per pixel
			ByteArray *data;
		
		
		private:
			
			value mValue;
		
		
	};
	
	
}


#endif