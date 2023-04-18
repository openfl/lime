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
		unsigned char *bytes = this->data->buffer->b;

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

			//this->data = new ArrayBufferView (height * stride);

		} else {

			this->data->Resize (height * stride);

		}

	}


	int ImageBuffer::Stride () {

		return width * (((bitsPerPixel + 3) & ~0x3) >> 3);

	}


	value ImageBuffer::Value () {

		return Value (alloc_empty_object ());

	}


	value ImageBuffer::Value (value imageBuffer) {

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

		alloc_field (imageBuffer, id_width, alloc_int (width));
		alloc_field (imageBuffer, id_height, alloc_int (height));
		alloc_field (imageBuffer, id_bitsPerPixel, alloc_int (bitsPerPixel));
		alloc_field (imageBuffer, id_data, data ? data->Value (val_field (imageBuffer, id_data)) : alloc_null ());
		alloc_field (imageBuffer, id_transparent, alloc_bool (transparent));
		alloc_field (imageBuffer, id_format, alloc_int (format));
		alloc_field (imageBuffer, id_premultiplied, alloc_bool (premultiplied));
		return imageBuffer;

	}


}