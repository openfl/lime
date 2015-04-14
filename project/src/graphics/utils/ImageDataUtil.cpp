#include <graphics/utils/ImageDataUtil.h>
#include <system/System.h>
#include <utils/QuickVec.h>


namespace lime {
	
	
	static int __alpha16[0xFF];
	static int __clamp[0xFF + 0xFF + 1];
	
	int initValues () {
		
		for (int i = 0; i < 256; i++) {
			
			// Seem to need +1 to get the same results as Haxe in multiplyAlpha
			__alpha16[i] = (i + 1) * ((1 << 16) / 0xFF); 
			
		}
		
		for (int i = 0; i < 0xFF; i++) {
			
			__clamp[i] = i;
			
		}
		
		for (int i = 0xFF; i < (0xFF + 0xFF + 1); i++) {
			
			__clamp[i] = 0xFF;
			
		}
		
		return 0;
		
	}
	
	static int initValues_ = initValues ();
	
	
	void ImageDataUtil::ColorTransform (Image* image, Rectangle* rect, ColorMatrix* colorMatrix) {
		
		int stride = image->buffer->width * 4;
		int offset;
		
		int rowStart = int (rect->y + image->offsetY);
		int rowEnd = int (rect->y + rect->height + image->offsetY);
		int columnStart = int (rect->x + image->offsetX);
		int columnEnd = int (rect->x + rect->width + image->offsetX);
		
		uint8_t* data = (uint8_t*)image->buffer->data->Bytes ();
		int r, g, b, a, ex = 0;
		
		float alphaMultiplier = colorMatrix->GetAlphaMultiplier ();
		float redMultiplier = colorMatrix->GetRedMultiplier ();
		float greenMultiplier = colorMatrix->GetGreenMultiplier ();
		float blueMultiplier = colorMatrix->GetBlueMultiplier ();
		int alphaOffset = colorMatrix->GetAlphaOffset ();
		int redOffset = colorMatrix->GetRedOffset ();
		int greenOffset = colorMatrix->GetGreenOffset ();
		int blueOffset = colorMatrix->GetBlueOffset ();
		
		for (int row = rowStart; row < rowEnd; row++) {
			
			for (int column = columnStart; column < columnEnd; column++) {
				
				offset = (row * stride) + (column * 4);
				
				a = (data[offset + 3] * alphaMultiplier) + alphaOffset;
				ex = a > 0xFF ? a - 0xFF : 0;
				b = (data[offset + 2] * blueMultiplier) + blueOffset + ex;
				ex = b > 0xFF ? b - 0xFF : 0;
				g = (data[offset + 1] * greenMultiplier) + greenOffset + ex;
				ex = g > 0xFF ? g - 0xFF : 0;
				r = (data[offset] * redMultiplier) + redOffset + ex;
				
				data[offset] = r > 0xFF ? 0xFF : r;
				data[offset + 1] = g > 0xFF ? 0xFF : g;
				data[offset + 2] = b > 0xFF ? 0xFF : b;
				data[offset + 3] = a > 0xFF ? 0xFF : a;
				
			}
			
		}
		
	}
	
	
	void ImageDataUtil::CopyChannel (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, int srcChannel, int destChannel) {
		
		int srcStride = sourceImage->buffer->width * 4;
		int srcPosition = ((sourceRect->x + sourceImage->offsetX) * 4) + (srcStride * (sourceRect->y + sourceImage->offsetY)) + srcChannel;
		int srcRowOffset = srcStride - int (4 * (sourceRect->width + sourceImage->offsetX));
		int srcRowEnd = 4 * (sourceRect->x + sourceImage->offsetX + sourceRect->width);
		uint8_t* srcData = (uint8_t*)sourceImage->buffer->data->Bytes ();
		
		int destStride = image->buffer->width * 4;
		int destPosition = ((destPoint->x + image->offsetX) * 4) + (destStride * (destPoint->y + image->offsetY)) + destChannel;
		int destRowOffset = destStride - int (4 * (sourceRect->width + image->offsetX));
		int destRowEnd = 4 * (destPoint->x + image->offsetX + sourceRect->width);
		uint8_t* destData = (uint8_t*)image->buffer->data->Bytes ();
		
		int length = sourceRect->width * sourceRect->height;
		
		for (int i = 0; i < length; i++) {
			
			destData[destPosition] = srcData[srcPosition];
			
			srcPosition += 4;
			destPosition += 4;
			
			if ((srcPosition % srcStride) > srcRowEnd) {
				
				srcPosition += srcRowOffset;
				
			}
			
			if ((destPosition % destStride) > destRowEnd) {
				
				destPosition += destRowOffset;
				
			}
			
		}
		
	}
	
	
	void ImageDataUtil::CopyPixels (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, bool mergeAlpha) {
		
		int rowOffset = int (destPoint->y + image->offsetY - sourceRect->y - sourceImage->offsetY);
		int columnOffset = int (destPoint->x + image->offsetX - sourceRect->x - sourceImage->offsetY);
		
		uint8_t* sourceData = (uint8_t*)sourceImage->buffer->data->Bytes ();
		int sourceStride = sourceImage->buffer->width * 4;
		int sourceOffset = 0;
		
		uint8_t* data = (uint8_t*)image->buffer->data->Bytes ();
		int stride = image->buffer->width * 4;
		int offset = 0;
		
		int rows = sourceRect->y + sourceRect->height + sourceImage->offsetY;
		int columns = sourceRect->x + sourceRect->width + sourceImage->offsetX;
		
		if (!mergeAlpha || !sourceImage->transparent) {
			
			for (int row = sourceRect->y + sourceImage->offsetY; row < rows; row++) {
				
				for (int column = sourceRect->x + sourceImage->offsetX; column < columns; column++) {
					
					sourceOffset = (row * sourceStride) + (column * 4);
					offset = ((row + rowOffset) * stride) + ((column + columnOffset) * 4);
					
					data[offset] = sourceData[sourceOffset];
					data[offset + 1] = sourceData[sourceOffset + 1];
					data[offset + 2] = sourceData[sourceOffset + 2];
					data[offset + 3] = sourceData[sourceOffset + 3];
					
				}
				
			}
			
		} else {
			
			float sourceAlpha;
			float oneMinusSourceAlpha;
			
			for (int row = sourceRect->y + sourceImage->offsetY; row < rows; row++) {
				
				for (int column = sourceRect->x + sourceImage->offsetX; column < columns; column++) {
					
					sourceOffset = (row * sourceStride) + (column * 4);
					offset = ((row + rowOffset) * stride) + ((column + columnOffset) * 4);
					
					sourceAlpha = sourceData[sourceOffset + 3] / 255;
					oneMinusSourceAlpha = (1 - sourceAlpha);
					
					data[offset] = __clamp[int (sourceData[sourceOffset] + (data[offset] * oneMinusSourceAlpha))];
					data[offset + 1] = __clamp[int (sourceData[sourceOffset + 1] + (data[offset + 1] * oneMinusSourceAlpha))];
					data[offset + 2] = __clamp[int (sourceData[sourceOffset + 2] + (data[offset + 2] * oneMinusSourceAlpha))];
					data[offset + 3] = __clamp[int (sourceData[sourceOffset + 3] + (data[offset + 3] * oneMinusSourceAlpha))];
					
				}
				
			}
			
		}
		
	}
	
	
	void ImageDataUtil::FillRect (Image* image, Rectangle* rect, int color) {
		
		int* data = (int*)image->buffer->data->Bytes ();
		
		if (rect->width == image->buffer->width && rect->height == image->buffer->height && rect->x == 0 && rect->y == 0 && image->offsetX == 0 && image->offsetY == 0) {
			
			int length = image->buffer->width * image->buffer->height;
			
			for (int i = 0; i < length; i++) {
				
				data[i] = color;
				
			}
			
		} else {
			
			int stride = image->buffer->width;
			int offset;
			
			int rowStart = int (rect->y + image->offsetY);
			int rowEnd = int (rect->y + rect->height + image->offsetY);
			int columnStart = int (rect->x + image->offsetX);
			int columnEnd = int (rect->x + rect->width + image->offsetX);
			
			for (int row = rowStart; row < rowEnd; row++) {
				
				for (int column = columnStart; column < columnEnd; column++) {
					
					offset = (row * stride) + (column);
					data[offset] = color;
					
				}
				
			}
			
		}
		
	}
	
	
	void ImageDataUtil::FloodFill (Image* image, int x, int y, int color) {
		
		uint8_t* data = (uint8_t*)image->buffer->data->Bytes ();
		
		int offset = (((y + image->offsetY) * (image->buffer->width * 4)) + ((x + image->offsetX) * 4));
		uint8_t hitColorR = data[offset + 0];
		uint8_t hitColorG = data[offset + 1];
		uint8_t hitColorB = data[offset + 2];
		uint8_t hitColorA = image->transparent ? data[offset + 3] : 0xFF;
		
		uint8_t r = (color >> 24) & 0xFF;
		uint8_t g = (color >> 16) & 0xFF;
		uint8_t b = (color >> 8) & 0xFF;
		uint8_t a = image->transparent ? color & 0xFF : 0xFF;
		
		if (hitColorR == r && hitColorG == g && hitColorB == b && hitColorA == a) return;
		
		int dx[4] = { 0, -1, 1, 0 };
		int dy[4] = { -1, 0, 0, 1 };
		
		int minX = -image->offsetX;
		int minY = -image->offsetY;
		int maxX = minX + image->width;
		int maxY = minY + image->height;
		
		QuickVec<int> queue = QuickVec<int> ();
		queue.push_back (x);
		queue.push_back (y);
		
		int curPointX, curPointY, i, nextPointX, nextPointY, nextPointOffset;
		
		while (queue.size () > 0) {
			
			curPointY = queue.qpop ();
			curPointX = queue.qpop ();
			
			for (i = 0; i < 4; i++) {
				
				nextPointX = curPointX + dx[i];
				nextPointY = curPointY + dy[i];
				
				if (nextPointX < minX || nextPointY < minY || nextPointX >= maxX || nextPointY >= maxY) {
					
					continue;
					
				}
				
				nextPointOffset = (nextPointY * image->width + nextPointX) * 4;
				
				if (data[nextPointOffset + 0] == hitColorR && data[nextPointOffset + 1] == hitColorG && data[nextPointOffset + 2] == hitColorB && data[nextPointOffset + 3] == hitColorA) {
					
					data[nextPointOffset + 0] = r;
					data[nextPointOffset + 1] = g;
					data[nextPointOffset + 2] = b;
					data[nextPointOffset + 3] = a;
					
					queue.push_back (nextPointX);
					queue.push_back (nextPointY);
					
				}
				
			}
			
		}
		
	}
	
	
	void ImageDataUtil::MultiplyAlpha (Image* image) {
		
		int a16 = 0;
		int length = image->buffer->data->Size () / 4;
		uint8_t* data = (uint8_t*)image->buffer->data->Bytes ();
		
		for (int i = 0; i < length; i++) {
			
			a16 = __alpha16[data[3]];
			data[0] = (data[0] * a16) >> 16;
			data[1] = (data[1] * a16) >> 16;
			data[2] = (data[2] * a16) >> 16;
			data += 4;
			
		}
		
	}
	
	
	void ImageDataUtil::UnmultiplyAlpha (Image* image) {
		
		int length = image->buffer->data->Size () / 4;
		uint8_t* data = (uint8_t*)image->buffer->data->Bytes ();
		
		int unmultiply;
		uint8_t a;
		
		for (int i = 0; i < length; i++) {
			
			a = data[3];
			
			if (a != 0) {
				
				unmultiply = 255.0 / a;
				data[0] = __clamp[data[0] * unmultiply];
				data[1] = __clamp[data[1] * unmultiply];
				data[2] = __clamp[data[2] * unmultiply];
				
			}
			
		}
		
	}
	
	
}