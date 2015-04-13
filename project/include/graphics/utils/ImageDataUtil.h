#ifndef LIME_GRAPHICS_UTILS_IMAGE_DATA_UTIL_H
#define LIME_GRAPHICS_UTILS_IMAGE_DATA_UTIL_H


#include <hx/CFFI.h>
#include <utils/ByteArray.h>


namespace lime {
	
	
	class ImageDataUtil {
		
		
		public:
			
			static void MultiplyAlpha (ByteArray *bytes);
			static void UnmultiplyAlpha (ByteArray *bytes);
		
		
	};
	
	
}


#endif