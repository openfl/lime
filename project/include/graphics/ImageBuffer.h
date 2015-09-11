#ifndef LIME_GRAPHICS_IMAGE_BUFFER_H
#define LIME_GRAPHICS_IMAGE_BUFFER_H


#include <hx/CFFI.h>
#include <graphics/PixelFormat.h>
#include <utils/Bytes.h>


namespace lime {
	
	
	class ImageBuffer {
		
		
		public:
			
			ImageBuffer ();
			ImageBuffer (value imageBuffer);
			~ImageBuffer ();
			
			void Blit (const unsigned char *data, int x, int y, int width, int height);
			void Resize (int width, int height, int bitsPerPixel = 32);
			int Stride ();
			value Value ();
			
			int bitsPerPixel;
			Bytes *data;
			PixelFormat format;
			int height;
			bool premultiplied;
			bool transparent;
			int width;
		
		private:
			
			value mValue;
		
		
	};
	
	
}


#endif