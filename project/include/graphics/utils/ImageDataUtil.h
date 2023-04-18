#ifndef LIME_GRAPHICS_UTILS_IMAGE_DATA_UTIL_H
#define LIME_GRAPHICS_UTILS_IMAGE_DATA_UTIL_H


#include <graphics/Image.h>
#include <graphics/PixelFormat.h>
#include <math/ColorMatrix.h>
#include <math/Rectangle.h>
#include <math/Vector2.h>
#include <system/CFFI.h>
#include <system/Endian.h>
#include <system/System.h>
#include <utils/Bytes.h>
#include <stdint.h>


namespace lime {


	class ImageDataUtil {


		public:

			static void ColorTransform (Image* image, Rectangle* rect, ColorMatrix* ColorMatrix);
			static void CopyChannel (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, int srcChannel, int destChannel);
			static void CopyPixels (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, Image* alphaImage, Vector2* alphaPoint, bool mergeAlpha);
			static void FillRect (Image* image, Rectangle* rect, int32_t color);
			static void FloodFill (Image* image, int x, int y, int32_t color);
			static void GetPixels (Image* image, Rectangle* rect, PixelFormat format, Bytes* pixels);
			static void Merge (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, int redMultiplier, int greenMultiplier, int blueMultiplier, int alphaMultiplier);
			static void MultiplyAlpha (Image* image);
			static void Resize (Image* image, ImageBuffer* buffer, int width, int height);
			static void SetFormat (Image* image, PixelFormat format);
			static void SetPixels (Image* image, Rectangle* rect, Bytes* bytes, int offset, PixelFormat format, Endian endian);
			static int Threshold (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, int operation, int32_t threshold, int32_t color, int32_t mask, bool copySource);
			static void UnmultiplyAlpha (Image* image);


	};


	class ImageDataView {


		public:

			ImageDataView (Image* image, Rectangle* rect);

			void Clip (int x, int y, int width, int height);
			bool HasRow (int y);
			void Offset (int x, int y);
			int Row (int y);

			int x;
			int y;
			int width;
			int height;

		private:

			void __Update ();

			int byteOffset;
			Image* image;
			Rectangle rect;
			int stride;


	};


}


#endif