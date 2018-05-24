#ifndef LIME_GRAPHICS_IMAGE_BUFFER_H
#define LIME_GRAPHICS_IMAGE_BUFFER_H


#include <hl.h>
#include <hx/CFFI.h>
#include <graphics/PixelFormat.h>
#include <utils/ArrayBufferView.h>


namespace lime {
	
	
	struct HL_ImageBuffer {
		
		hl_type* t;
		int bitsPerPixel;
		HL_ArrayBufferView* data;
		PixelFormat format;
		int height;
		bool premultiplied;
		bool transparent;
		int width;
		void* __srcBitmapData;
		// void* __srcCanvas;
		void* __srcContext;
		// void* __srcCustom;
		void* __srcImage;
		void* __srcImageData;
		
	};
	
	
	class ImageBuffer {
		
		
		public:
			
			ImageBuffer ();
			ImageBuffer (value imageBuffer);
			ImageBuffer (HL_ImageBuffer* imageBuffer);
			~ImageBuffer ();
			
			void Blit (const unsigned char *data, int x, int y, int width, int height);
			void Resize (int width, int height, int bitsPerPixel = 32);
			int Stride ();
			value Value ();
			
			int bitsPerPixel;
			ArrayBufferView *data;
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