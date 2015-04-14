#ifndef LIME_GRAPHICS_UTILS_IMAGE_DATA_UTIL_H
#define LIME_GRAPHICS_UTILS_IMAGE_DATA_UTIL_H


#include <hx/CFFI.h>
#include <graphics/Image.h>
#include <math/ColorMatrix.h>
#include <math/Rectangle.h>


namespace lime {
	
	
	class ImageDataUtil {
		
		
		public:
			
			static void ColorTransform (Image *image, Rectangle *rect, ColorMatrix *ColorMatrix);
			static void MultiplyAlpha (Image *image);
			static void UnmultiplyAlpha (Image *image);
		
		
	};
	
	
}


#endif