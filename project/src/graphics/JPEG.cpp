extern "C" {

	#include <sys/types.h>
	#include <stdio.h>
	#include <jpeglib.h>

}

#include <graphics/ImageData.h>
#include <graphics/JPEG.h>


namespace lime {


	extern FILE *OpenRead (const char *);


	bool JPEG::Decode (const char *path, ImageData *imageData) {

		struct jpeg_decompress_struct cinfo;
		struct jpeg_error_mgr jerr;

		FILE *file = OpenRead (path);

		cinfo.err = jpeg_std_error (&jerr);
		jpeg_create_decompress (&cinfo);
		jpeg_stdio_src (&cinfo, file);

		if (jpeg_read_header (&cinfo, TRUE) == JPEG_HEADER_OK) {

			jpeg_start_decompress (&cinfo);
			imageData->width = cinfo.output_width;
			imageData->height = cinfo.output_height;
			int components = cinfo.num_components;
			imageData->data = new ByteArray (imageData->width * imageData->height * 4);

			unsigned char *bytes = imageData->data->Bytes();
			unsigned char *scanline = new unsigned char [imageData->width * imageData->height * components];

			while (cinfo.output_scanline < cinfo.output_height) {

				jpeg_read_scanlines (&cinfo, &scanline, 1);

				// convert 24-bit scanline to 32-bit
				const unsigned char *line = scanline;
				const unsigned char *const end = line + imageData->width * components;

				while (line != end) {

					*bytes++ = *line++;
					*bytes++ = *line++;
					*bytes++ = *line++;
					*bytes++ = 0xFF;

				}

			}

			delete[] scanline;

			jpeg_finish_decompress (&cinfo);
		}

		fclose (file);
		jpeg_destroy_decompress (&cinfo);

		return true;
	}

}
