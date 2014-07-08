extern "C" {
	
	#include <png.h>
	#define PNG_SIG_SIZE 8
	
}

#include <graphics/Image.h>
#include <graphics/PNG.h>
#include <utils/ByteArray.h>


namespace lime {
	
	
	bool PNG::Decode (const char *path, Image *image) {
		
		unsigned char png_sig[PNG_SIG_SIZE];
		png_structp png_ptr;
		png_infop info_ptr;
		png_uint_32 width, height;
		int bit_depth, color_type;
		
		FILE *file = OpenRead (path);
		if (!file) return false;
		
		// verify the PNG signature
		int read = fread (png_sig, PNG_SIG_SIZE, 1, file);
		if (png_sig_cmp (png_sig, 0, PNG_SIG_SIZE)) {
			
			fclose (file);
			return false;
			
		}
		
		if ((png_ptr = png_create_read_struct (PNG_LIBPNG_VER_STRING, NULL, NULL, NULL)) == NULL) {
			
			fclose (file);
			return false;
			
		}
		
		if ((info_ptr = png_create_info_struct (png_ptr)) == NULL) {
			
			png_destroy_read_struct (&png_ptr, (png_infopp)NULL, (png_infopp)NULL);
			fclose (file);
			return false;
			
		}
		
		// sets the point which libpng will jump back to in the case of an error
		if (setjmp (png_jmpbuf (png_ptr))) {
			
			png_destroy_read_struct (&png_ptr, &info_ptr, (png_infopp)NULL);
			fclose (file);
			return false;
			
		}
		
		png_init_io (png_ptr, file);
		png_set_sig_bytes (png_ptr, PNG_SIG_SIZE);
		png_read_info (png_ptr, info_ptr);
		
		width = png_get_image_width (png_ptr, info_ptr);
		height = png_get_image_height (png_ptr, info_ptr);
		color_type = png_get_color_type (png_ptr, info_ptr);
		bit_depth = png_get_bit_depth (png_ptr, info_ptr);
		
		png_set_expand (png_ptr);
		png_set_filler (png_ptr, 0xff, PNG_FILLER_AFTER);
		
		if (bit_depth == 16)
			png_set_strip_16 (png_ptr);
		
		const unsigned int stride = width * 4;
		image->width = width;
		image->height = height;
		image->data = new ByteArray (height * stride);
		
		png_bytepp row_ptrs = new png_bytep[height];
		unsigned char *bytes = image->data->Bytes ();
		
		for (size_t i = 0; i < height; i++) {
			
			row_ptrs[i] = bytes + i * stride;
			
		}
		
		png_read_image (png_ptr, row_ptrs);
		png_read_end (png_ptr, NULL);
		
		delete[] row_ptrs;
		png_destroy_read_struct (&png_ptr, &info_ptr, (png_infopp)NULL);
		
		return true;
		
	}
	
	
	static bool Encode (Image *image, ByteArray *bytes) {
		
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