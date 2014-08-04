#ifndef LIME_GRAPHICS_IMAGE_BUFFER_H
#define LIME_GRAPHICS_IMAGE_BUFFER_H


#include <hx/CFFI.h>
#include <utils/ByteArray.h>


namespace lime {
	
	
	class ImageBuffer {
		
		
		public:
			
			ImageBuffer ();
			~ImageBuffer ();
			
			void Blit (const unsigned char *data, int x, int y, int width, int height);
			void Resize (int width, int height, int bpp = 4);
			value Value ();
			
			int bpp;
			ByteArray *data;
			int height;
			int width;
		
		private:
			
			value mValue;
		
		
	};
	
	
}


#endif