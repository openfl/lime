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
		
		if (!mergeAlpha || !sourceImage->buffer->transparent) {
			
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
			float destAlpha;
			float outA;
			float oneMinusSourceAlpha;
			
			for (int row = sourceRect->y + sourceImage->offsetY; row < rows; row++) {
				
				for (int column = sourceRect->x + sourceImage->offsetX; column < columns; column++) {
					
					sourceOffset = (row * sourceStride) + (column * 4);
					offset = ((row + rowOffset) * stride) + ((column + columnOffset) * 4);
					
					sourceAlpha = sourceData[sourceOffset + 3] / 255.0;
					destAlpha = data[offset + 3] / 255.0;
					oneMinusSourceAlpha = (1 - sourceAlpha);
					
					outA = sourceAlpha + destAlpha * oneMinusSourceAlpha;
					data[offset + 0] = __clamp[int (0.5 + ((sourceData[sourceOffset + 0] * sourceAlpha + data[offset + 0] * destAlpha * oneMinusSourceAlpha) / outA))];
					data[offset + 1] = __clamp[int (0.5 + ((sourceData[sourceOffset + 1] * sourceAlpha + data[offset + 1] * destAlpha * oneMinusSourceAlpha) / outA))];
					data[offset + 2] = __clamp[int (0.5 + ((sourceData[sourceOffset + 2] * sourceAlpha + data[offset + 2] * destAlpha * oneMinusSourceAlpha) / outA))];
					data[offset + 3] = __clamp[int (0.5 + (outA * 255.0))];
					
				}
				
			}
			
		}
		
	}
	
	
	void ImageDataUtil::FillRect (Image* image, Rectangle* rect, int color) {
		
		int* data = (int*)image->buffer->data->Bytes ();
		
		if (rect->width == image->buffer->width && rect->height == image->buffer->height && rect->x == 0 && rect->y == 0 && image->offsetX == 0 && image->offsetY == 0) {
			
			int length = image->buffer->width * image->buffer->height;
			
			if (color == 0 || color == 0xFFFFFFFF || (color & 0xFF == (color >> 8) & 0xFF && (color >> 8) & 0xFF == (color >> 16) & 0xFF && (color >> 16) & 0xFF == (color >> 24) & 0xFF)) {
				
				memset ((uint8_t*)data, color & 0xFF, length * 4);
				
			} else {
				
				for (int i = 0; i < length; i++) {
					
					data[i] = color;
					
				}
				
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
	
	
	void ImageDataUtil::GetPixels (Image* image, Rectangle* rect, PixelFormat format, ByteArray* pixels) {
		
		int length = int (rect->width * rect->height);
		pixels->Resize (length * 4);
		
		if (format == RGBA && rect->width == image->buffer->width && rect->height == image->buffer->height && rect->x == 0 && rect->y == 0) {
			
			memcpy (pixels->Bytes (), image->buffer->data->Bytes (), image->buffer->data->Size ());
			return;
			
		}
		
		uint8_t* data = (uint8_t*)pixels->Bytes (); 
		uint8_t* srcData = (uint8_t*)image->buffer->data->Bytes ();
		
		int srcStride = int (image->buffer->width * 4);
		int srcPosition = int ((rect->x * 4) + (srcStride * rect->y));
		int srcRowOffset = srcStride - int (4 * rect->width);
		int srcRowEnd = int (4 * (rect->x + rect->width));
		
		if (format == ARGB) {
			
			for (int i = 0; i < length; i++) {
				
				data[i * 4 + 1] = srcData[srcPosition++];
				data[i * 4 + 2] = srcData[srcPosition++];
				data[i * 4 + 3] = srcData[srcPosition++];
				data[i * 4] = srcData[srcPosition++];
				
				if ((srcPosition % srcStride) > srcRowEnd) {
					
					srcPosition += srcRowOffset;
					
				}
				
			}
			
		} else {
			
			for (int i = 0; i < length; i++) {
				
				data[i * 4] = srcData[srcPosition++];
				data[i * 4 + 1] = srcData[srcPosition++];
				data[i * 4 + 2] = srcData[srcPosition++];
				data[i * 4 + 3] = srcData[srcPosition++];
				
				if ((srcPosition % srcStride) > srcRowEnd) {
					
					srcPosition += srcRowOffset;
					
				}
				
			}
			
		}
		
	}
	
	
	void ImageDataUtil::Merge (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, int redMultiplier, int greenMultiplier, int blueMultiplier, int alphaMultiplier) {
		
		int rowOffset = int (destPoint->y + image->offsetY - sourceRect->y - sourceImage->offsetY);
		int columnOffset = int (destPoint->x + image->offsetX - sourceRect->x - sourceImage->offsetY);
		
		uint8_t* sourceData = (uint8_t*)sourceImage->buffer->data->Bytes ();
		int sourceStride = sourceImage->buffer->width * 4;
		int sourceOffset = 0;
		
		uint8_t* data = (uint8_t*)image->buffer->data->Bytes ();
		int stride = image->buffer->width * 4;
		int offset = 0;
		
		int rowEnd = int (sourceRect->y + sourceRect->height + sourceImage->offsetY);
		int columnEnd = int (sourceRect->x + sourceRect->width + sourceImage->offsetX);
		
		for (int row = int (sourceRect->y + sourceImage->offsetY); row < rowEnd; row++) {
			
			for (int column = int (sourceRect->x + sourceImage->offsetX); column < columnEnd; column++) {
				
				sourceOffset = (row * sourceStride) + (column * 4);
				offset = ((row + rowOffset) * stride) + ((column + columnOffset) * 4);
				
				data[offset] = int (((sourceData[offset] * redMultiplier) + (data[offset] * (256 - redMultiplier))) / 256);
				data[offset + 1] = int (((sourceData[offset + 1] * greenMultiplier) + (data[offset + 1] * (256 - greenMultiplier))) / 256);
				data[offset + 2] = int (((sourceData[offset + 2] * blueMultiplier) + (data[offset + 2] * (256 - blueMultiplier))) / 256);
				data[offset + 3] = int (((sourceData[offset + 3] * alphaMultiplier) + (data[offset + 3] * (256 - alphaMultiplier))) / 256);
				
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
	
	
	void ImageDataUtil::Resize (Image* image, ImageBuffer* buffer, int newWidth, int newHeight) {
		
		int imageWidth = image->width;
		int imageHeight = image->height;
		
		uint8_t* data = (uint8_t*)image->buffer->data->Bytes ();
		uint8_t* newData = (uint8_t*)buffer->data->Bytes ();
		
		int sourceIndex, sourceIndexX, sourceIndexY, sourceIndexXY, index;
		int sourceX, sourceY;
		float u, v, uRatio, vRatio, uOpposite, vOpposite;
		
		for (int y = 0; y < newHeight; y++) {
			
			for (int x = 0; x < newWidth; x++) {
				
				u = ((x + 0.5) / newWidth) * imageWidth - 0.5;
				v = ((y + 0.5) / newHeight) * imageHeight - 0.5;
				
				sourceX = int (u);
				sourceY = int (v);
				
				sourceIndex = (sourceY * imageWidth + sourceX) * 4;
				sourceIndexX = (sourceX < imageWidth - 1) ? sourceIndex + 4 : sourceIndex;
				sourceIndexY = (sourceY < imageHeight - 1) ? sourceIndex + (imageWidth * 4) : sourceIndex;
				sourceIndexXY = (sourceIndexX != sourceIndex) ? sourceIndexY + 4 : sourceIndexY;
				
				index = (y * newWidth + x) * 4;
				
				uRatio = u - sourceX;
				vRatio = v - sourceY;
				uOpposite = 1 - uRatio;
				vOpposite = 1 - vRatio;
				
				newData[index] = int ((data[sourceIndex] * uOpposite + data[sourceIndexX] * uRatio) * vOpposite + (data[sourceIndexY] * uOpposite + data[sourceIndexXY] * uRatio) * vRatio);
				newData[index + 1] = int ((data[sourceIndex + 1] * uOpposite + data[sourceIndexX + 1] * uRatio) * vOpposite + (data[sourceIndexY + 1] * uOpposite + data[sourceIndexXY + 1] * uRatio) * vRatio);
				newData[index + 2] = int ((data[sourceIndex + 2] * uOpposite + data[sourceIndexX + 2] * uRatio) * vOpposite + (data[sourceIndexY + 2] * uOpposite + data[sourceIndexXY + 2] * uRatio) * vRatio);
				
				// Maybe it would be better to not weigh colors with an alpha of zero, but the below should help prevent black fringes caused by transparent pixels made visible
				
				if (data[sourceIndexX + 3] == 0 || data[sourceIndexY + 3] == 0 || data[sourceIndexXY + 3] == 0) {
					
					newData[index + 3] = 0;
					
				} else {
					
					newData[index + 3] = data[sourceIndex + 3];
					
				}
				
			}
			
		}
		
	}
	
	
	void ImageDataUtil::SetFormat (Image* image, PixelFormat format) {
		
		int index, a16;
		int length = image->buffer->data->Size () / 4;
		int r1, g1, b1, a1, r2, g2, b2, a2;
		int r, g, b, a;
		
		switch (image->buffer->format) {
			
			case RGBA:
				
				r1 = 0;
				g1 = 1;
				b1 = 2;
				a1 = 3;
				break;
			
			case ARGB:
				
				r1 = 1;
				g1 = 2;
				b1 = 3;
				a1 = 0;
				break;
			
			case BGRA:
				
				r1 = 2;
				g1 = 1;
				b1 = 0;
				a1 = 3;
				break;
			
		}
		
		switch (format) {
			
			case RGBA:
				
				r2 = 0;
				g2 = 1;
				b2 = 2;
				a2 = 3;
				break;
			
			case ARGB:
				
				r2 = 1;
				g2 = 2;
				b2 = 3;
				a2 = 0;
				break;
			
			case BGRA:
				
				r2 = 2;
				g2 = 1;
				b2 = 0;
				a2 = 3;
				break;
			
		}
		
		unsigned char* data = image->buffer->data->Bytes ();
		
		for (int i = 0; i < length; i++) {
			
			index = i * 4;
			
			r = data[index + r1];
			g = data[index + g1];
			b = data[index + b1];
			a = data[index + a1];
			
			data[index + r2] = r;
			data[index + g2] = g;
			data[index + b2] = b;
			data[index + a2] = a;
			
		}
		
	}
	
	
	void ImageDataUtil::SetPixels (Image* image, Rectangle* rect, ByteArray* bytes, PixelFormat format) {
		
		if (format == RGBA && rect->width == image->buffer->width && rect->height == image->buffer->height && rect->x == 0 && rect->y == 0) {
			
			memcpy (image->buffer->data->Bytes (), bytes->Bytes (), bytes->Size ());
			return;
			
		}
		
		int offset = int (image->buffer->width * (rect->y + image->offsetX) + (rect->x + image->offsetY));
		int boundR = int ((rect->x + rect->width + image->offsetX));
		int width = image->buffer->width;
		int color;
		
		if (format == ARGB) {
			
			int pos = offset * 4;
			int len = int (rect->width * rect->height * 4);
			uint8_t* data = (uint8_t*)image->buffer->data->Bytes ();
			uint8_t* byteArray = (uint8_t*)bytes->Bytes ();
			
			for (int i = 0; i < len; i += 4) {
				
				
				if (((pos) % (width * 4)) >= boundR * 4) {
					
					pos += (width - boundR) * 4;
					
				}
				
				data[pos] = byteArray[i + 1];
				data[pos + 1] = byteArray[i + 2];
				data[pos + 2] = byteArray[i + 3];
				data[pos + 3] = byteArray[i];
				pos += 4;
				
			}
			
		} else {
			
			int pos = offset;
			int len = int (rect->width * rect->height);
			int* data = (int*)image->buffer->data->Bytes ();
			int* byteArray = (int*)bytes->Bytes ();
			
			// TODO: memcpy rows at once
			
			for (int i = 0; i < len; i++) {
				
				if (((pos) % (width)) >= boundR) {
					
					pos += (width - boundR);
					
				}
				
				data[pos] = byteArray[i];
				pos++;
				
			}
			
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