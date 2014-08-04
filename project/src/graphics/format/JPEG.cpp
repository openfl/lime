extern "C" {
	
	#include <sys/types.h>
	#include <stdio.h>
	#include <jpeglib.h>
	
}

#include <setjmp.h>
#include <graphics/format/JPEG.h>
#include <utils/FileIO.h>


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
			
			return true;
			
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
			return true;
			
		}
		
		
		static void my_term_source (j_decompress_ptr cinfo) {}
		
	};
	
	
	bool JPEG::Decode (Resource *resource, ImageBuffer* imageBuffer) {
		
		struct jpeg_decompress_struct cinfo;
		
		//struct jpeg_error_mgr jerr;
		//cinfo.err = jpeg_std_error (&jerr);
		
		struct ErrorData jpegError;
		cinfo.err = jpeg_std_error (&jpegError.base);
		jpegError.base.error_exit = OnError;
		jpegError.base.output_message = OnOutput;
		
		FILE *file = NULL;
		
		if (setjmp (jpegError.on_error)) {
			
			if (file) {
				
				lime::fclose (file);
				
			}
			
			jpeg_destroy_decompress (&cinfo);
			return false;
			
		}
		
		jpeg_create_decompress (&cinfo);
		
		if (resource->path) {
			
			file = lime::fopen (resource->path, "rb");
			jpeg_stdio_src (&cinfo, file);
			
		} else {
			
			MySrcManager manager (resource->data->Bytes (), resource->data->Size ());
			cinfo.src = &manager.pub;
			
		}
		
		bool decoded = false;
		
		if (jpeg_read_header (&cinfo, TRUE) == JPEG_HEADER_OK) {
			
			cinfo.out_color_space = JCS_RGB;
			
			jpeg_start_decompress (&cinfo);
			int components = cinfo.num_components;
			imageBuffer->Resize (cinfo.output_width, cinfo.output_height);
			
			unsigned char *bytes = imageBuffer->data->Bytes ();
			unsigned char *scanline = new unsigned char [imageBuffer->width * imageBuffer->height * components];
			
			while (cinfo.output_scanline < cinfo.output_height) {
				
				jpeg_read_scanlines (&cinfo, &scanline, 1);
				
				// convert 24-bit scanline to 32-bit
				const unsigned char *line = scanline;
				const unsigned char *const end = line + imageBuffer->width * components;
				
				while (line != end) {
					
					*bytes++ = *line++;
					*bytes++ = *line++;
					*bytes++ = *line++;
					*bytes++ = 0xFF;
					
				}
				
			}
			
			delete[] scanline;
			
			jpeg_finish_decompress (&cinfo);
			decoded = true;
			
		}
		
		if (file) {
			
			lime::fclose (file);
			
		}
		
		jpeg_destroy_decompress (&cinfo);
		return decoded;
		
	}
	
	
}