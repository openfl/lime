#include <hx/CFFIPrime.h>
#include <system/CFFIPointer.h>
#include <system/System.h>
#include <utils/Bytes.h>
#include <vorbis/vorbisfile.h>


namespace lime {
	
	
	static int id_bitstream;
	static int id_high;
	static int id_low;
	static int id_returnValue;
	static value int64Value;
	static value readValue;
	static bool init = false;
	
	
	value allocInt64 (ogg_int64_t val) {
		
		ogg_int32_t low = val;
		ogg_int32_t high = (val >> 32);
		
		if (!init) {
			
			id_bitstream = val_id ("bitstream");
			id_high = val_id ("high");
			id_low = val_id ("low");
			id_returnValue = val_id ("returnValue");
			int64Value = alloc_empty_object ();
			readValue = alloc_empty_object ();
			init = true;
			
		}
		
		alloc_field (int64Value, id_low, alloc_int (low));
		alloc_field (int64Value, id_high, alloc_int (high));
		
		return int64Value;
		
	}
	
	
	typedef struct {
		
		unsigned char* data;
		ogg_int64_t size;
		ogg_int64_t pos;
		
	} Vorbis_BufferData;
	
	
	static size_t Vorbis_BufferRead (void* dest, size_t eltSize, size_t nelts, Vorbis_BufferData* src) {
		
		size_t len = eltSize * nelts;
		
		if ((src->pos + len) > src->size) {
			
			len = src->size - src->pos;
			
		}
		
		if (len > 0) {
			
			memcpy (dest, (src->data + src->pos), len);
			src->pos += len;
			
		}
		
		return len;
		
	}
	
	
	static int Vorbis_BufferSeek (Vorbis_BufferData* src, ogg_int64_t pos, int whence) {
		
		switch (whence) {
			
			case SEEK_CUR:
				
				src->pos += pos;
				break;
			
			case SEEK_END:
				
				src->pos = src->size - pos;
				break;
			
			case SEEK_SET:
				
				src->pos = pos;
				break;
			
			default:
				
				return -1;
			
		}
		
		if (src->pos < 0) {
			
			src->pos = 0;
			return -1;
			
		}
		
		if (src->pos > src->size) {
			
			return -1;
			
		}
		
		return 0;
		
	}
	
	
	static int Vorbis_BufferClose (Vorbis_BufferData* src) {
		
		return 0;
		
	}
	
	
	static long Vorbis_BufferTell (Vorbis_BufferData *src) {
		
		return src->pos;
		
	}
	
	
	static ov_callbacks VORBIS_CALLBACKS_BUFFER = {
		
		(size_t (*)(void *, size_t, size_t, void *)) Vorbis_BufferRead,
		(int (*)(void *, ogg_int64_t, int)) Vorbis_BufferSeek,
		(int (*)(void *)) Vorbis_BufferClose,
		(long (*)(void *)) Vorbis_BufferTell
		
	};
	
	
	void lime_vorbis_file_clear (value vorbisFile);
	
	
	void gc_vorbis_file (value vorbisFile) {
		
		lime_vorbis_file_clear (vorbisFile);
		
	}
	
	
	int lime_vorbis_file_bitrate (value vorbisFile, int bitstream) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_bitrate (file, bitstream);
		
	}
	
	
	int lime_vorbis_file_bitrate_instant (value vorbisFile) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_bitrate_instant (file);
		
	}
	
	
	void lime_vorbis_file_clear (value vorbisFile) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ov_clear (file);
		
	}
	
	
	value lime_vorbis_file_comment (value vorbisFile, int bitstream) {
		
		return alloc_null ();
		
	}
	
	
	value lime_vorbis_file_crosslap (value vorbisFile, value otherVorbisFile) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		OggVorbis_File* otherFile = (OggVorbis_File*)(uintptr_t)val_data (otherVorbisFile);
		return alloc_int (ov_crosslap (file, otherFile));
		
	}
	
	
	value lime_vorbis_file_info (value vorbisFile, int bitstream) {
		
		return alloc_null ();
		
	}
	
	
	value lime_vorbis_file_from_bytes (value data) {
		
		OggVorbis_File* vorbisFile = new OggVorbis_File;
		memset (vorbisFile, 0, sizeof (OggVorbis_File));
		
		Bytes bytes;
		bytes.Set (data);
		
		Vorbis_BufferData buffer = Vorbis_BufferData ();
		buffer.data = bytes.Data ();
		buffer.size = bytes.Length ();
		buffer.pos = 0;
		
		if (ov_open_callbacks (&buffer, vorbisFile, NULL, 0, VORBIS_CALLBACKS_BUFFER) != 0) {
			
			free (vorbisFile);
			return alloc_null ();
			
		}
		
		return CFFIPointer ((void*)(uintptr_t)vorbisFile, gc_vorbis_file);
		
	}
	
	
	value lime_vorbis_file_from_file (HxString path) {
		
		if (path.c_str ()) {
			
			FILE_HANDLE *file = lime::fopen (path.c_str (), "rb");
			
			if (file) {
				
				OggVorbis_File* vorbisFile = new OggVorbis_File;
				memset (vorbisFile, 0, sizeof (OggVorbis_File));
				
				if (file->isFile ()) {
					
					if (ov_open (file->getFile (), vorbisFile, NULL, file->getLength ()) != 0) {
						
						free (vorbisFile);
						lime::fclose (file);
						return alloc_null ();
						
					}
					
				} else {
					
					lime::fclose (file);
					Bytes* bytes = new Bytes (path.c_str ());
					
					Vorbis_BufferData buffer = Vorbis_BufferData ();
					buffer.data = bytes->Data ();
					buffer.size = bytes->Length ();
					buffer.pos = 0;
					
					if (ov_open_callbacks (&buffer, vorbisFile, NULL, 0, VORBIS_CALLBACKS_BUFFER) != 0) {
						
						delete bytes;
						free (vorbisFile);
						return alloc_null ();
						
					}
					
				}
				
				return CFFIPointer ((void*)(uintptr_t)vorbisFile, gc_vorbis_file);
				
			}
			
		}
		
		return alloc_null ();
		
	}
	
	
	int lime_vorbis_file_pcm_seek (value vorbisFile, value posLow, value posHigh) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ogg_int64_t pos = ((ogg_int64_t)val_number (posHigh) << 32) | (ogg_int64_t)val_number (posLow);
		return ov_pcm_seek (file, pos);
		
	}
	
	
	int lime_vorbis_file_pcm_seek_lap (value vorbisFile, value posLow, value posHigh) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ogg_int64_t pos = ((ogg_int64_t)val_number (posHigh) << 32) | (ogg_int64_t)val_number (posLow);
		return ov_pcm_seek_lap (file, pos);
		
	}
	
	
	int lime_vorbis_file_pcm_seek_page (value vorbisFile, value posLow, value posHigh) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ogg_int64_t pos = ((ogg_int64_t)val_number (posHigh) << 32) | (ogg_int64_t)val_number (posLow);
		return ov_pcm_seek_page (file, pos);
		
	}
	
	
	int lime_vorbis_file_pcm_seek_page_lap (value vorbisFile, value posLow, value posHigh) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ogg_int64_t pos = ((ogg_int64_t)val_number (posHigh) << 32) | (ogg_int64_t)val_number (posLow);
		return ov_pcm_seek_page_lap (file, pos);
		
	}
	
	
	value lime_vorbis_file_pcm_tell (value vorbisFile) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return allocInt64 (ov_pcm_tell (file));
		
	}
	
	
	value lime_vorbis_file_pcm_total (value vorbisFile, int bitstream) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return allocInt64 (ov_pcm_total (file, bitstream));
		
	}
	
	
	int lime_vorbis_file_raw_seek (value vorbisFile, value posLow, value posHigh) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ogg_int64_t pos = ((ogg_int64_t)val_number (posHigh) << 32) | (ogg_int64_t)val_number (posLow);
		return ov_raw_seek (file, pos);
		
	}
	
	
	int lime_vorbis_file_raw_seek_lap (value vorbisFile, value posLow, value posHigh) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ogg_int64_t pos = ((ogg_int64_t)val_number (posHigh) << 32) | (ogg_int64_t)val_number (posLow);
		return ov_raw_seek_lap (file, pos);
		
	}
	
	
	value lime_vorbis_file_raw_tell (value vorbisFile) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return allocInt64 (ov_raw_tell (file));
		
	}
	
	
	value lime_vorbis_file_raw_total (value vorbisFile, int bitstream) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return allocInt64 (ov_raw_total (file, bitstream));
		
	}
	
	
	value lime_vorbis_file_read (value vorbisFile, value buffer, int length, bool bigendianp, int word, bool sgned) {
		
		Bytes bytes;
		bytes.Set (buffer);
		
		int bitstream;
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		long result = ov_read (file, (char*)bytes.Data (), length, bigendianp, word, sgned, &bitstream);
		
		alloc_field (readValue, id_bitstream, alloc_int (bitstream));
		alloc_field (readValue, id_returnValue, alloc_int (result));
		
		return readValue;
		
	}
	
	
	value lime_vorbis_file_read_float (value vorbisFile, value pcmChannels, int samples) {
		
		//Bytes bytes;
		//bytes.Set (pcmChannels);
		//
		//int bitstream;
		//
		//OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		//long result = ov_read_float (file, (char*)bytes.Data (), samples, &bitstream);
		//
		//alloc_field (readValue, id_bitstream, alloc_int (bitstream));
		//alloc_field (readValue, id_returnValue, alloc_int (result));
		//
		//return readValue;
		
		return alloc_null ();
		
	}
	
	
	bool lime_vorbis_file_seekable (value vorbisFile) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_seekable (file);
		
	}
	
	
	int lime_vorbis_file_serial_number (value vorbisFile, int bitstream) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_serialnumber (file, bitstream);
		
	}
	
	
	int lime_vorbis_file_streams (value vorbisFile) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_streams (file);
		
	}
	
	
	int lime_vorbis_file_time_seek (value vorbisFile, double s) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_time_seek (file, s);
		
	}
	
	
	int lime_vorbis_file_time_seek_lap (value vorbisFile, double s) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_time_seek_lap (file, s);
		
	}
	
	
	int lime_vorbis_file_time_seek_page (value vorbisFile, double s) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_time_seek_page (file, s);
		
	}
	
	
	int lime_vorbis_file_time_seek_page_lap (value vorbisFile, double s) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_time_seek_page_lap (file, s);
		
	}
	
	
	double lime_vorbis_file_time_tell (value vorbisFile) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_time_tell (file);
		
	}
	
	
	double lime_vorbis_file_time_total (value vorbisFile, int bitstream) {
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_time_total (file, bitstream);
		
	}
	
	
	DEFINE_PRIME2 (lime_vorbis_file_bitrate);
	DEFINE_PRIME1 (lime_vorbis_file_bitrate_instant);
	DEFINE_PRIME1v (lime_vorbis_file_clear);
	DEFINE_PRIME2 (lime_vorbis_file_comment);
	DEFINE_PRIME2v (lime_vorbis_file_crosslap);
	DEFINE_PRIME1 (lime_vorbis_file_from_bytes);
	DEFINE_PRIME1 (lime_vorbis_file_from_file);
	DEFINE_PRIME2 (lime_vorbis_file_info);
	DEFINE_PRIME3 (lime_vorbis_file_pcm_seek);
	DEFINE_PRIME3 (lime_vorbis_file_pcm_seek_lap);
	DEFINE_PRIME3 (lime_vorbis_file_pcm_seek_page);
	DEFINE_PRIME3 (lime_vorbis_file_pcm_seek_page_lap);
	DEFINE_PRIME1 (lime_vorbis_file_pcm_tell);
	DEFINE_PRIME2 (lime_vorbis_file_pcm_total);
	DEFINE_PRIME3 (lime_vorbis_file_raw_seek);
	DEFINE_PRIME3 (lime_vorbis_file_raw_seek_lap);
	DEFINE_PRIME1 (lime_vorbis_file_raw_tell);
	DEFINE_PRIME2 (lime_vorbis_file_raw_total);
	DEFINE_PRIME6 (lime_vorbis_file_read);
	DEFINE_PRIME3 (lime_vorbis_file_read_float);
	DEFINE_PRIME1 (lime_vorbis_file_seekable);
	DEFINE_PRIME2 (lime_vorbis_file_serial_number);
	DEFINE_PRIME1 (lime_vorbis_file_streams);
	DEFINE_PRIME2 (lime_vorbis_file_time_seek);
	DEFINE_PRIME2 (lime_vorbis_file_time_seek_lap);
	DEFINE_PRIME2 (lime_vorbis_file_time_seek_page);
	DEFINE_PRIME2 (lime_vorbis_file_time_seek_page_lap);
	DEFINE_PRIME1 (lime_vorbis_file_time_tell);
	DEFINE_PRIME2 (lime_vorbis_file_time_total);
	
	
}


extern "C" int lime_vorbis_register_prims () {
	
	return 0;
	
}