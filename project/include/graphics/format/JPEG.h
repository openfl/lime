#ifndef LIME_GRAPHICS_FORMAT_JPEG_H
#define LIME_GRAPHICS_FORMAT_JPEG_H


#include <graphics/ImageBuffer.h>
#include <utils/ByteArray.h>
#include <utils/Resource.h>


namespace lime {
	
	
	class JPEG {
		
		
		public:
			
			static bool Decode (Resource *resource, ImageBuffer *imageBuffer);
			static bool Encode (ImageBuffer *imageBuffer, ByteArray *bytes, int quality);
		
		
	};
	
	
}


#endif