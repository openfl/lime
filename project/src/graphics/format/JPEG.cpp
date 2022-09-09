#include <system/System.h>
extern "C" {

	#include <sys/types.h>
	#include <stdio.h>
	#include <jpeglib.h>

}

#include <setjmp.h>
#include <graphics/format/JPEG.h>


namespace lime {


	struct ErrorData {

		struct jpeg_error_mgr base;
		jmp_buf on_error;

	};


	static void OnOutput (j_common_ptr cinfo) {}


	static void OnError (j_common_ptr cinfo) {

		ErrorData * err = (ErrorData *)cinfo->err;
		longjmp (err->on_error, 1);

	}


	struct MySrcManager {


		MySrcManager (const JOCTET *inData, int inLen) : mData (inData), mLen (inLen) {

			pub.init_source = my_init_source;
			pub.fill_input_buffer = my_fill_input_buffer;
			pub.skip_input_data = my_skip_input_data;
			pub.resync_to_restart = my_resync_to_restart;
			pub.term_source = my_term_source;
			pub.next_input_byte = 0;
			pub.bytes_in_buffer = 0;
			mUsed = false;
			mEOI[0] = 0xff;
			mEOI[1] = JPEG_EOI;

		}


		struct jpeg_source_mgr pub;   /* public fields */
		const JOCTET * mData;
		size_t mLen;
		bool   mUsed;
		unsigned char mEOI[2];


		static void my_init_source (j_decompress_ptr cinfo) {

			MySrcManager *man = (MySrcManager *)cinfo->src;
			man->mUsed = false;

		}


		static boolean my_fill_input_buffer (j_decompress_ptr cinfo) {

			MySrcManager *man = (MySrcManager *)cinfo->src;

			if (man->mUsed) {

				man->pub.next_input_byte = man->mEOI;
				man->pub.bytes_in_buffer = 2;

			} else {
				man->pub.next_input_byte = man->mData;
				man->pub.bytes_in_buffer = man->mLen;
				man->mUsed = true;

			}

			return TRUE;

		}


		static void my_skip_input_data (j_decompress_ptr cinfo, long num_bytes) {

			MySrcManager *man = (MySrcManager *)cinfo->src;
			man->pub.next_input_byte += num_bytes;
			man->pub.bytes_in_buffer -= num_bytes;

			// was < 0 and was always false PJK 16JUN12
			if (man->pub.bytes_in_buffer == 0) {

				man->pub.next_input_byte = man->mEOI;
				man->pub.bytes_in_buffer = 2;

			}

		}


		static boolean my_resync_to_restart (j_decompress_ptr cinfo, int desired) {

			MySrcManager *man = (MySrcManager *)cinfo->src;
			man->mUsed = false;
			return TRUE;

		}


		static void my_term_source (j_decompress_ptr cinfo) {}

	};


	struct MyDestManager {


		enum { BUF_SIZE = 4096 };
		struct jpeg_destination_mgr pub;   /* public fields */
		QuickVec<unsigned char> mOutput;
		unsigned char   mTmpBuf[BUF_SIZE];


		MyDestManager () {

			pub.init_destination = init_buffer;
			pub.empty_output_buffer = copy_buffer;
			pub.term_destination = term_buffer;
			pub.next_output_byte = mTmpBuf;
			pub.free_in_buffer = BUF_SIZE;

		}


		void CopyBuffer () {

			mOutput.append (mTmpBuf, BUF_SIZE);
			pub.next_output_byte = mTmpBuf;
			pub.free_in_buffer = BUF_SIZE;

		}


		void TermBuffer () {

			mOutput.append (mTmpBuf, BUF_SIZE - pub.free_in_buffer);

		}


		static void init_buffer (jpeg_compress_struct* cinfo) {}


		static boolean copy_buffer (jpeg_compress_struct* cinfo) {

			MyDestManager *man = (MyDestManager *)cinfo->dest;
			man->CopyBuffer ();
			return TRUE;

		}


		static void term_buffer (jpeg_compress_struct* cinfo) {

			MyDestManager *man = (MyDestManager *)cinfo->dest;
			man->TermBuffer ();

		}


	};


	bool JPEG::Decode (Resource *resource, ImageBuffer* imageBuffer, bool decodeData) {

		struct jpeg_decompress_struct cinfo;

		//struct jpeg_error_mgr jerr;
		//cinfo.err = jpeg_std_error (&jerr);

		struct ErrorData jpegError;
		cinfo.err = jpeg_std_error (&jpegError.base);
		jpegError.base.error_exit = OnError;
		jpegError.base.output_message = OnOutput;

		FILE_HANDLE *file = NULL;
		Bytes *data = NULL;
		MySrcManager *manager = NULL;

		if (resource->path) {

			file = lime::fopen (resource->path, "rb");

			if (!file) {

				return false;

			}

		}

		if (setjmp (jpegError.on_error)) {

			if (file) {

				lime::fclose (file);

			}

			if (manager) {

				delete manager;

			}

			if (data) {

				delete data;

			}

			jpeg_destroy_decompress (&cinfo);
			return false;

		}

		jpeg_create_decompress (&cinfo);
		jpeg_save_markers (&cinfo, JPEG_APP0 + 14, 0xFF);

		if (file) {

			if (file->isFile ()) {

				jpeg_stdio_src (&cinfo, file->getFile ());

			} else {

				data = new Bytes ();
				data->ReadFile (resource->path);
				manager = new MySrcManager (data->b, data->length);
				cinfo.src = &manager->pub;

			}

		} else {

			manager = new MySrcManager (resource->data->b, resource->data->length);
			cinfo.src = &manager->pub;

		}

		bool decoded = false;

		if (jpeg_read_header (&cinfo, TRUE) == JPEG_HEADER_OK) {

			switch (cinfo.jpeg_color_space) {

				case JCS_CMYK:
				case JCS_YCCK:

					cinfo.out_color_space = JCS_CMYK;
					break;

				case JCS_GRAYSCALE:
				case JCS_RGB:
				case JCS_YCbCr:
				default:

					cinfo.out_color_space = JCS_RGB;
					break;

				// case JCS_BG_RGB:
				// case JCS_BG_YCC:
				// case JCS_UNKNOWN:

			}

			if (decodeData) {

				jpeg_start_decompress (&cinfo);

				int components = cinfo.output_components;
				imageBuffer->Resize (cinfo.output_width, cinfo.output_height, 32);

				unsigned char *bytes = imageBuffer->data->buffer->b;
				unsigned char *scanline = new unsigned char [imageBuffer->width * components];

				if (cinfo.out_color_space == JCS_CMYK) {

					bool invert = false;
					jpeg_saved_marker_ptr marker;
					marker = cinfo.marker_list;

					while (marker) {

						if (marker->marker == JPEG_APP0 + 14 && marker->data_length >= 12 && !strncmp ((const char*)marker->data, "Adobe", 5)) {

							// Are there other transforms?
							invert = true;

						}

						marker = marker->next;

					}

					while (cinfo.output_scanline < cinfo.output_height) {

						jpeg_read_scanlines (&cinfo, &scanline, 1);

						const unsigned char *line = scanline;
						const unsigned char *const end = line + imageBuffer->width * components;
						unsigned char c, m, y, k;

						while (line < end) {

							if (invert) {

								c = 0xFF - *line++;
								m = 0xFF - *line++;
								y = 0xFF - *line++;
								k = 0xFF - *line++;

							} else {

								c = *line++;
								m = *line++;
								y = *line++;
								k = *line++;

							}

							*bytes++ = (unsigned char)((0xFF - c) * (0xFF - k) / 0xFF);
							*bytes++ = (unsigned char)((0xFF - m) * (0xFF - k) / 0xFF);
							*bytes++ = (unsigned char)((0xFF - y) * (0xFF - k) / 0xFF);
							*bytes++ = 0xFF;

						}

					}

				} else {

					while (cinfo.output_scanline < cinfo.output_height) {

						jpeg_read_scanlines (&cinfo, &scanline, 1);

						// convert 24-bit scanline to 32-bit
						const unsigned char *line = scanline;
						const unsigned char *const end = line + imageBuffer->width * components;

						while (line < end) {

							*bytes++ = *line++;
							*bytes++ = *line++;
							*bytes++ = *line++;
							*bytes++ = 0xFF;

						}

					}

				}

				delete[] scanline;

				jpeg_finish_decompress (&cinfo);

			} else {

				imageBuffer->width = cinfo.image_width;
				imageBuffer->height = cinfo.image_height;

			}

			decoded = true;

		}

		if (file) {

			lime::fclose (file);

		}

		if (manager) {

			delete manager;

		}

		if (data) {

			delete data;

		}

		jpeg_destroy_decompress (&cinfo);
		return decoded;

	}


	bool JPEG::Encode (ImageBuffer *imageBuffer, Bytes *bytes, int quality) {

		struct jpeg_compress_struct cinfo;

		struct ErrorData jpegError;
		cinfo.err = jpeg_std_error (&jpegError.base);
		jpegError.base.error_exit = OnError;
		jpegError.base.output_message = OnOutput;

		MyDestManager dest;

		int w = imageBuffer->width;
		int h = imageBuffer->height;
		QuickVec<unsigned char> row_buf (w * 3);

		jpeg_create_compress (&cinfo);

		if (setjmp (jpegError.on_error)) {

			jpeg_destroy_compress (&cinfo);
			return false;

		}

		cinfo.dest = (jpeg_destination_mgr *)&dest;

		cinfo.image_width = w;
		cinfo.image_height = h;
		cinfo.input_components = 3;
		cinfo.in_color_space = JCS_RGB;

		jpeg_set_defaults (&cinfo);
		jpeg_set_quality (&cinfo, quality, TRUE);
		jpeg_start_compress (&cinfo, TRUE);

		JSAMPROW row_pointer = &row_buf[0];
		unsigned char* imageData = imageBuffer->data->buffer->b;
		int stride = imageBuffer->Stride ();

		while (cinfo.next_scanline < cinfo.image_height) {

			const unsigned char *src = (const unsigned char *)(imageData + (stride * cinfo.next_scanline));
			unsigned char *dest = &row_buf[0];

			for(int x = 0; x < w; x++) {

				dest[0] = src[0];
				dest[1] = src[1];
				dest[2] = src[2];
				dest += 3;
				src += 4;

			}

			jpeg_write_scanlines (&cinfo, &row_pointer, 1);

		}

		jpeg_finish_compress (&cinfo);

		int size = dest.mOutput.size ();

		if (size > 0) {

			bytes->Resize (size);
			memcpy (bytes->b, &dest.mOutput[0], size);

		}

		return true;

	}


}
