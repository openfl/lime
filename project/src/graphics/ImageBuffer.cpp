#include <graphics/ImageBuffer.h>


namespace lime {
	
	
	static int id_bitsPerPixel;
	static int id_data;
	static int id_format;
	static int id_height;
	static int id_premultiplied;
	static int id_transparent;
	static int id_width;
	static bool init = false;
	
	
	ImageBuffer::ImageBuffer () {
		
		width = 0;
		height = 0;
		bitsPerPixel = 32;
		format = RGBA32;
		data = 0;
		premultiplied = false;
		transparent = false;
		_buffer = 0;
		_value = 0;
		
	}
	
	
	ImageBuffer::ImageBuffer (value imageBuffer) {
		
		if (!init) {
			
			id_bitsPerPixel = val_id ("bitsPerPixel");
			id_transparent = val_id ("transparent");
			id_data = val_id ("data");
			id_width = val_id ("width");
			id_height = val_id ("height");
			id_format = val_id ("format");
			id_premultiplied = val_id ("premultiplied");
			init = true;
			
		}
		
		if (!val_is_null (imageBuffer)) {
			
			width = val_int (val_field (imageBuffer, id_width));
			height = val_int (val_field (imageBuffer, id_height));
			bitsPerPixel = val_int (val_field (imageBuffer, id_bitsPerPixel));
			format = (PixelFormat)val_int (val_field (imageBuffer, id_format));
			transparent = val_bool (val_field (imageBuffer, id_transparent));
			premultiplied = val_bool (val_field (imageBuffer, id_premultiplied));
			data = new ArrayBufferView (val_field (imageBuffer, id_data));
			
		} else {
			
			width = 0;
			height = 0;
			bitsPerPixel = 32;
			format = RGBA32;
			data = 0;
			premultiplied = false;
			transparent = false;
			
		}
		
		_buffer = 0;
		_value = imageBuffer;
		
	}
	
	
	ImageBuffer::ImageBuffer (HL_ImageBuffer* imageBuffer) {
		
		if (imageBuffer) {
			
			width = imageBuffer->width;
			height = imageBuffer->height;
			bitsPerPixel = imageBuffer->bitsPerPixel;
			format = imageBuffer->format;
			transparent = imageBuffer->transparent;
			premultiplied = imageBuffer->premultiplied;
			data = new ArrayBufferView (imageBuffer->data);
			_buffer = imageBuffer;
			
		} else {
			
			width = 0;
			height = 0;
			bitsPerPixel = 32;
			format = RGBA32;
			data = 0;
			premultiplied = false;
			transparent = false;
			_buffer = 0;
			
		}
		
		_value = 0;
		
	}
	
	
	ImageBuffer::~ImageBuffer () {
		
		if (data) {
			
			delete data;
			
		}
		
	}
	
	
	void ImageBuffer::Blit (const unsigned char *data, int x, int y, int width, int height) {
		
		if (x < 0 || x + width > this->width || y < 0 || y + height > this->height) {
			
			return;
			
		}
		
		int stride = Stride ();
		unsigned char *bytes = this->data->buffer->Data ();
		
		for (int i = 0; i < height; i++) {
			
			memcpy (&bytes[(i + y) * this->width + x], &data[i * width], stride);
			
		}
		
	}
	
	
	void ImageBuffer::Resize (int width, int height, int bitsPerPixel) {
		
		this->bitsPerPixel = bitsPerPixel;
		this->width = width;
		this->height = height;
		
		int stride = Stride ();
		
		if (!this->data) {
			
			this->data = new ArrayBufferView (height * stride);
			
		} else {
			
			this->data->Resize (height * stride);
			
		}
		
	}
	
	
	int ImageBuffer::Stride () {
		
		return width * (((bitsPerPixel + 3) & ~0x3) >> 3);
		
	}
	
	
	void* ImageBuffer::Value () {
		
		if (_buffer) {
			
			_buffer->width = width;
			_buffer->height = height;
			_buffer->bitsPerPixel = bitsPerPixel;
			_buffer->format = format;
			_buffer->transparent = transparent;
			_buffer->premultiplied = premultiplied;
			//_buffer->data
			return _buffer;
			
		} else {
			
			if (!init) {
				
				id_bitsPerPixel = val_id ("bitsPerPixel");
				id_transparent = val_id ("transparent");
				id_data = val_id ("data");
				id_width = val_id ("width");
				id_height = val_id ("height");
				id_format = val_id ("format");
				id_premultiplied = val_id ("premultiplied");
				init = true;
				
			}
			
			if (val_is_null (_value)) {
				
				_value = alloc_empty_object ();
				
			}
			
			alloc_field (_value, id_width, alloc_int (width));
			alloc_field (_value, id_height, alloc_int (height));
			alloc_field (_value, id_bitsPerPixel, alloc_int (bitsPerPixel));
			alloc_field (_value, id_data, data ? data->Value () : alloc_null ());
			alloc_field (_value, id_transparent, alloc_bool (transparent));
			alloc_field (_value, id_format, alloc_int (format));
			alloc_field (_value, id_premultiplied, alloc_bool (premultiplied));
			return _value;
			
		}
		
	}
	
	
}