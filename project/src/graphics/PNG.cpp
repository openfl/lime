extern "C" {
	
	//#include <png.h>
	
}

#include <hx/CFFI.h>
#include <graphics/PNG.h>
#include <setjmp.h>


namespace lime {
	
	
	static int id_data;
	static int id_height;
	static int id_width;
	static bool init = false;
	
	
	/*static void user_error_fn (png_structp png_ptr, png_const_charp error_msg) {
		
		longjmp (png_ptr->jmpbuf, 1);
		
	}
	
	static void user_warning_fn (png_structp png_ptr, png_const_charp warning_msg) { }
	static void user_read_data_fn (png_structp png_ptr, png_bytep data, png_size_t length) {
		
		png_voidp buffer = png_get_io_ptr (png_ptr);
		((ReadBuf *)buffer)->Read (data, length);
		
	}

	void user_write_data (png_structp png_ptr, png_bytep data, png_size_t length) {
		
		QuickVec<unsigned char> *buffer = (QuickVec<unsigned char> *)png_get_io_ptr (png_ptr);
		buffer->append ((unsigned char *)data, (int)length);
		
	}
	
	void user_flush_data (png_structp png_ptr) { }*/
	
	
	void PNG::Decode (ByteArray bytes, value imageData) {
		
		/*if (!init) {
			
			id_data = val_id ("data");
			id_height = val_id ("height");
			id_width = val_id ("width");
			init = true;
			
		}
		
		png_structp png_ptr;
		png_infop info_ptr;
		png_uint_32 width, height;
		int bit_depth, color_type, interlace_type;
		
		png_ptr = png_create_read_struct (PNG_LIBPNG_VER_STRING, 0, user_error_fn, user_warning_fn);
		
		if (png_ptr == NULL)
			return;
		
		info_ptr = png_create_info_struct (png_ptr);
		
		if (info_ptr == NULL) {
			
			png_destroy_read_struct (&png_ptr, (png_infopp)NULL, (png_infopp)NULL);
			return;
			
		}
		
		unsigned char* bytes[width * height * 4];
		RenderTarget target;
		
		if (setjmp (png_jmpbuf (png_ptr))) {
			
			if (bytes) {
				
				delete bytes;
				
			}
			
			png_destroy_read_struct (&png_ptr, &info_ptr, (png_infopp)NULL);
			return;
			
		}
		
		ReadBuf buffer (inData, inDataLen);
		
		//if (inFile) {
			
			//png_init_io (png_ptr, inFile);
			
		//} else {
			
			png_set_read_fn (png_ptr, (void *)&buffer, user_read_data_fn);
			
		//}
		
		png_read_info (png_ptr, info_ptr);
		png_get_IHDR (png_ptr, info_ptr, &width, &height, &bit_depth, &color_type, &interlace_type, NULL, NULL);
		
		bool has_alpha = (color_type == PNG_COLOR_TYPE_GRAY_ALPHA || color_type == PNG_COLOR_TYPE_RGB_ALPHA || png_get_valid (png_ptr, info_ptr, PNG_INFO_tRNS));
		
		png_set_expand (png_ptr);
		png_set_filler (png_ptr, 0xff, PNG_FILLER_AFTER);
		
		png_set_palette_to_rgb (png_ptr);
		png_set_gray_to_rgb (png_ptr);
		
		if (bit_depth == 16)
			png_set_strip_16 (png_ptr);
		
		png_set_bgr (png_ptr);
		
		//result = new ImageData ();
		//result.width = width;
		//result.height = height;
		//result.data = uint8[width * height * 4];
		
		png_read_png (png_ptr, (png_bytepp)&bytes);
		
		png_read_end (png_ptr, info_ptr);
		png_destroy_read_struct (&png_ptr, &info_ptr, (png_infopp)NULL);
		
		
		value object = (KeyEvent::eventObject ? KeyEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_code, alloc_int (event->code));
			alloc_field (object, id_type, alloc_int (event->type));
			
		
		alloc_field (imageData, id_width, alloc_int (width));
		alloc_field (imageData, id_height, alloc_int (height));
		alloc_field (imageData, id_data, alloc_int (bytes));
		
		return result;*/
		
	}
	
	
	static bool Encode (ImageData *imageData, ByteArray *bytes) {
		
		return true;
		
		/*png_structp png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, user_error_fn, user_warning_fn);

		if (!png_ptr)
			return false;

		png_infop info_ptr = png_create_info_struct(png_ptr);
		if (!info_ptr)
			return false;

		if (setjmp(png_jmpbuf(png_ptr)))
		{
			png_destroy_write_struct(&png_ptr, &info_ptr );
			return false;
		}

		QuickVec<uint8> out_buffer;

		png_set_write_fn(png_ptr, &out_buffer, user_write_data, user_flush_data);

		int w = inSurface->Width();
		int h = inSurface->Height();

		int bit_depth = 8;
		int color_type = (inSurface->Format()&pfHasAlpha) ?
		PNG_COLOR_TYPE_RGB_ALPHA :
		PNG_COLOR_TYPE_RGB;
		png_set_IHDR(png_ptr, info_ptr, w, h,
		bit_depth, color_type, PNG_INTERLACE_NONE,
		PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

		png_write_info(png_ptr, info_ptr);

		bool do_alpha = color_type==PNG_COLOR_TYPE_RGBA;

		{
		QuickVec<uint8> row_data(w*4);
		png_bytep row = &row_data[0];
		for(int y=0;y<h;y++)
		{
		uint8 *buf = &row_data[0];
		const uint8 *src = (const uint8 *)inSurface->Row(y);
		for(int x=0;x<w;x++)
		{
		buf[0] = src[2];
		buf[1] = src[1];
		buf[2] = src[0];
		src+=3;
		buf+=3;
		if (do_alpha)
		*buf++ = *src;
		src++;
		}
		png_write_rows(png_ptr, &row, 1);
		}
		}

		png_write_end(png_ptr, NULL);

		*outBytes = ByteArray(out_buffer);

		return true;*/
	}
	
	
}