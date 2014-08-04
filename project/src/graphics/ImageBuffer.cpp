#include <graphics/ImageBuffer.h>


namespace lime {
	
	
	static int id_data;
	static int id_height;
	static int id_width;
	static int id_bpp;
	static bool init = false;
	
	
	ImageBuffer::ImageBuffer () {
		
		width = 0;
		height = 0;
		bpp = 4;
		data = 0;
		
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
			
			id_width = val_id ("width");
			id_height = val_id ("height");
			id_data = val_id ("data");
			id_bpp = val_id ("bpp");
			init = true;
			
		}
		
		mValue = alloc_empty_object ();
		alloc_field (mValue, id_width, alloc_int (width));
		alloc_field (mValue, id_height, alloc_int (height));
		alloc_field (mValue, id_bpp, alloc_int (bpp));
		alloc_field (mValue, id_data, data->mValue);
		return mValue;
		
	}
	
	
}