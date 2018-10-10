extern "C" {

	#include <png.h>
	#include <pngstruct.h>
	#define PNG_SIG_SIZE 8

}

#include <setjmp.h>
#include <graphics/format/PNG.h>
#include <graphics/ImageBuffer.h>
#include <system/System.h>
#include <utils/Bytes.h>
#include <utils/QuickVec.h>


namespace lime {


	struct ReadBuffer {

		ReadBuffer (const unsigned char* data, int length) : data (data), length (length), position (0) {}

		bool Read (unsigned char* out, int count) {

			if (position >= length) return false;

			if (count > length - position) {

				memcpy (out, data + position, length - position);
				position = length;

			} else {

				memcpy (out, data + position, count);
				position += count;

			}

			return true;

		}

		char unused; // the first byte gets corrupted when passed to libpng?
		const unsigned char* data;
		int length;
		int position;

	};


	static void user_error_fn (png_structp png_ptr, png_const_charp error_msg) {

		longjmp (png_ptr->jmp_buf_local, 1);

	}


	static void user_read_data_fn (png_structp png_ptr, png_bytep data, png_size_t length) {

		ReadBuffer* buffer = (ReadBuffer*)png_get_io_ptr (png_ptr);
		if (!buffer->Read (data, length)) {
			png_error (png_ptr, "Read Error");
		}

	}

	static void user_warning_fn (png_structp png_ptr, png_const_charp warning_msg) {}


	void user_write_data (png_structp png_ptr, png_bytep data, png_size_t length) {

		QuickVec<unsigned char> *buffer = (QuickVec<unsigned char> *)png_get_io_ptr (png_ptr);
		buffer->append ((unsigned char *)data,(int)length);

	}


	void user_flush_data (png_structp png_ptr) {}


	bool PNG::Decode (Resource *resource, ImageBuffer *imageBuffer, bool decodeData) {

		png_structp png_ptr;
		png_infop info_ptr;
		png_uint_32 width, height;
		int bit_depth, color_type, interlace_type;

		FILE_HANDLE* file = NULL;
		Bytes* data = NULL;

		if (resource->path) {

			file = lime::fopen (resource->path, "rb");
			if (!file) return false;

			unsigned char png_sig[PNG_SIG_SIZE];
			int read = lime::fread (&png_sig, PNG_SIG_SIZE, 1, file);
			if (png_sig_cmp (png_sig, 0, PNG_SIG_SIZE)) {

				lime::fclose (file);
				return false;

			}

		} else {

			if (png_sig_cmp (resource->data->b, 0, PNG_SIG_SIZE)) {

				return false;

			}

		}

		if ((png_ptr = png_create_read_struct (PNG_LIBPNG_VER_STRING, NULL, NULL, NULL)) == NULL) {

			if (file) lime::fclose (file);
			return false;

		}

		if ((info_ptr = png_create_info_struct (png_ptr)) == NULL) {

			png_destroy_read_struct (&png_ptr, (png_infopp)NULL, (png_infopp)NULL);
			if (file) lime::fclose (file);
			return false;

		}

		// sets the point which libpng will jump back to in the case of an error
		if (setjmp (png_jmpbuf (png_ptr))) {

			png_destroy_read_struct (&png_ptr, &info_ptr, (png_infopp)NULL);
			if (file) lime::fclose (file);
			return false;

		}

		if (file) {

			if (file->isFile ()) {

				png_init_io (png_ptr, file->getFile ());
				png_set_sig_bytes (png_ptr, PNG_SIG_SIZE);

			} else {

				data = new Bytes ();
				data->ReadFile (resource->path);
				ReadBuffer buffer (data->b, data->length);
				png_set_read_fn (png_ptr, &buffer, user_read_data_fn);

			}

		} else {

			ReadBuffer buffer (resource->data->b, resource->data->length);
			png_set_read_fn (png_ptr, &buffer, user_read_data_fn);

		}

		png_read_info (png_ptr, info_ptr);
		png_get_IHDR (png_ptr, info_ptr, &width, &height, &bit_depth, &color_type, &interlace_type, NULL, NULL);

		if (decodeData) {

			//bool has_alpha = (color_type == PNG_COLOR_TYPE_GRAY_ALPHA || color_type == PNG_COLOR_TYPE_RGB_ALPHA || png_get_valid (png_ptr, info_ptr, PNG_INFO_tRNS));

			png_set_expand (png_ptr);

			png_set_filler (png_ptr, 0xff, PNG_FILLER_AFTER);
			//png_set_gray_1_2_4_to_8 (png_ptr);
			png_set_palette_to_rgb (png_ptr);
			png_set_gray_to_rgb (png_ptr);

			if (bit_depth < 8) {

				png_set_packing (png_ptr);

			} else if (bit_depth == 16) {

				png_set_scale_16 (png_ptr);

			}

			//png_set_bgr (png_ptr);

			imageBuffer->Resize (width, height, 32);

			const unsigned int stride = imageBuffer->Stride ();
			unsigned char *bytes = imageBuffer->data->buffer->b;

			int number_of_passes = png_set_interlace_handling (png_ptr);

			for (int pass = 0; pass < number_of_passes; pass++) {

				for (int i = 0; i < height; i++) {

					png_bytep anAddr = (png_bytep)(bytes + i * stride);
					png_read_rows (png_ptr, (png_bytepp) &anAddr, NULL, 1);

				}

			}

			png_read_end (png_ptr, NULL);

		} else {

			imageBuffer->width = width;
			imageBuffer->height = height;

		}

		png_destroy_read_struct (&png_ptr, &info_ptr, (png_infopp)NULL);

		if (file) lime::fclose (file);
		if (data) delete data;

		return true;

	}


	bool PNG::Encode (ImageBuffer *imageBuffer, Bytes* bytes) {

		png_structp png_ptr = png_create_write_struct (PNG_LIBPNG_VER_STRING, NULL, user_error_fn, user_warning_fn);

		if (!png_ptr) {

			return false;

		}

		png_infop info_ptr = png_create_info_struct (png_ptr);

		if (!info_ptr) {

			return false;

		}

		if (setjmp (png_jmpbuf (png_ptr))) {

			png_destroy_write_struct (&png_ptr, &info_ptr);
			return false;

		}

		QuickVec<unsigned char> out_buffer;

		png_set_write_fn (png_ptr, &out_buffer, user_write_data, user_flush_data);

		int w = imageBuffer->width;
		int h = imageBuffer->height;

		int bit_depth = 8;
		//int color_type = (inSurface->Format () & pfHasAlpha) ? PNG_COLOR_TYPE_RGB_ALPHA : PNG_COLOR_TYPE_RGB;
		int color_type = PNG_COLOR_TYPE_RGB_ALPHA;
		png_set_IHDR (png_ptr, info_ptr, w, h, bit_depth, color_type, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

		png_write_info (png_ptr, info_ptr);

		bool do_alpha = (color_type == PNG_COLOR_TYPE_RGBA);
		unsigned char* imageData = imageBuffer->data->buffer->b;
		int stride = imageBuffer->Stride ();

		{
			QuickVec<unsigned char> row_data (w * 4);
			png_bytep row = &row_data[0];

			for (int y = 0; y < h; y++) {

				unsigned char *buf = &row_data[0];
				const unsigned char *src = (const unsigned char *)(imageData + (stride * y));

				for (int x = 0; x < w; x++) {

					buf[0] = src[0];
					buf[1] = src[1];
					buf[2] = src[2];
					src += 3;
					buf += 3;

					if (do_alpha) {

						*buf++ = *src;

					}

					src++;

				}

				png_write_rows (png_ptr, &row, 1);

			}

		}

		png_write_end (png_ptr, NULL);

		int size = out_buffer.size ();

		if (size > 0) {

			bytes->Resize (size);
			memcpy (bytes->b, &out_buffer[0], size);

		}

		return true;

	}


}