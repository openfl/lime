#ifndef LIME_GRAPHICS_UTILS_IMAGE_DATA_UTIL_H
#define LIME_GRAPHICS_UTILS_IMAGE_DATA_UTIL_H


#include <hx/CFFI.h>
#include <graphics/Image.h>
#include <math/ColorMatrix.h>
#include <math/Rectangle.h>
#include <math/Vector2.h>
#include <system/System.h>


namespace lime {
	
	
	class ImageDataUtil {
		
		
		public:
			
			static void ColorTransform (Image *image, Rectangle *rect, ColorMatrix *ColorMatrix);
			static void CopyChannel (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, int srcChannel, int destChannel);
			static void CopyPixels (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, bool mergeAlpha);
			static void FillRect (Image* image, Rectangle* rect, int color);
			static void FloodFill (Image* image, int x, int y, int color);
			static void MultiplyAlpha (Image *image);
			static void UnmultiplyAlpha (Image *image);
		
		
	};
	
	
}


#endif