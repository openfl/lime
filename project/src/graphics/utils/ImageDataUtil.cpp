#include <graphics/utils/ImageDataUtil.h>
#include <system/System.h>


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