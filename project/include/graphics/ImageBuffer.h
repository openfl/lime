#ifndef LIME_GRAPHICS_IMAGE_BUFFER_H
#define LIME_GRAPHICS_IMAGE_BUFFER_H


#include <hx/CFFI.h>
#include <graphics/PixelFormat.h>
#include <utils/ByteArray.h>


namespace lime {
	
	
	class ImageBuffer {
		
		
		public:
			
			ImageBuffer ();
			ImageBuffer (value imageBuffer);
			~ImageBuffer ();
			
			void Blit (const unsigned char *data, int x, int y, int width, int height);
			void Resize (int width, int height, int bpp = 4);
			value Value ();
			
			int bpp;
			ByteArray *data;
			PixelFormat format;
			int height;
			int width;
			bool transparent;
		
		private:
			
			value mValue;
		
		
	};
	
	
}


#endif