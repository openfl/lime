#include <graphics/ImageBuffer.h>


namespace lime {
	
	
	static int id_bitsPerPixel;
	static int id_bpp;
	static int id_buffer;
	static int id_data;
	static int id_format;
	static int id_height;
	static int id_width;
	static int id_transparent;
	static bool init = false;
	
	
	ImageBuffer::ImageBuffer () {
		
		width = 0;
		height = 0;
		bpp = 4;
		format = RGBA;
		data = 0;
		transparent = false;
		
	}
	
	
	ImageBuffer::ImageBuffer (value imageBuffer) {
		
		if (!init) {
			
			id_bpp = val_id ("bpp");
			id_bitsPerPixel = val_id ("bitsPerPixel");
			id_transparent = val_id ("transparent");
			id_buffer = val_id ("buffer");
			id_width = val_id ("width");
			id_height = val_id ("height");
			id_data = val_id ("data");
			id_format = val_id ("format");
			init = true;
			
		}
		
		width = val_int (val_field (imageBuffer, id_width));
		height = val_int (val_field (imageBuffer, id_height));
		bpp = val_int (val_field (imageBuffer, id_bitsPerPixel));
		format = (PixelFormat)val_int (val_field (imageBuffer, id_format));
		transparent = val_bool (val_field (imageBuffer, id_transparent));
		value data_value = val_field (imageBuffer, id_data);
		value buffer_value = val_field (data_value, id_buffer);
		
		//if (val_is_buffer (buffer_value))
			data = new ByteArray (buffer_value);
		//else
			//data = new ByteArray (data_value);
		
	}
	
	
	ImageBuffer::~ImageBuffer () {
		
		delete data;
		
	}
	
	
	void ImageBuffer::Blit (const unsigned char *data, int x, int y, int width, int height) {
		
		if (x < 0 || x + width > this->width || y < 0 || y + height > this->height) {
			
			return;
			
		}
		
		unsigned char *bytes = this->data->Bytes ();
		
		for (int i = 0; i < height; i++) {
			
			memcpy (&bytes[(i + y) * this->width + x], &data[i * width], width * bpp);
			
		}
		
	}
	
	
	void ImageBuffer::Resize (int width, int height, int bpp) {
		
		this->bpp = bpp;
		this->width = width;
		this->height = height;
		if (this->data) delete this->data;
		this->data = new ByteArray (width * height * bpp);
		
	}
	
	
	value ImageBuffer::Value () {
		
		if (!init) {
			
			id_bpp = val_id ("bpp");
			id_bitsPerPixel = val_id ("bitsPerPixel");
			id_transparent = val_id ("transparent");
			id_buffer = val_id ("buffer");
			id_width = val_id ("width");
			id_height = val_id ("height");
			id_data = val_id ("data");
			id_format = val_id ("format");
			init = true;
			
		}
		
		mValue = alloc_empty_object ();
		alloc_field (mValue, id_width, alloc_int (width));
		alloc_field (mValue, id_height, alloc_int (height));
		alloc_field (mValue, id_bpp, alloc_int (bpp));
		alloc_field (mValue, id_transparent, alloc_bool (transparent));
		alloc_field (mValue, id_data, data->mValue);
		alloc_field (mValue, id_format, alloc_int (format));
		return mValue;
		
	}
	
	
}