#include <media/codecs/vorbis/VorbisFile.h>
#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <utils/Bytes.h>


namespace lime {
	
	
	static int id_bitrateUpper;
	static int id_bitrateNominal;
	static int id_bitrateLower;
	static int id_bitstream;
	static int id_channels;
	static int id_high;
	static int id_low;
	static int id_rate;
	static int id_returnValue;
	static int id_version;
	static value infoValue;
	static value int64Value;
	static value readValue;
	static bool init = false;
	
	
	inline void _initializeVorbis () {
		
		if (!init) {
			
			id_bitrateUpper = val_id ("bitrateUpper");
			id_bitrateNominal = val_id ("bitrateNominal");
			id_bitrateLower = val_id ("bitrateLower");
			id_bitstream = val_id ("bitstream");
			id_channels = val_id ("channels");
			id_high = val_id ("high");
			id_low = val_id ("low");
			id_rate = val_id ("rate");
			id_returnValue = val_id ("returnValue");
			id_version = val_id ("version");
			
			infoValue = alloc_empty_object ();
			int64Value = alloc_empty_object ();
			readValue = alloc_empty_object ();
			
			value* root = alloc_root ();
			*root = infoValue;
			
			value* root2 = alloc_root ();
			*root2 = int64Value;
			
			value* root3 = alloc_root ();
			*root3 = readValue;
			
			init = true;
			
		}
		
	}
	
	
	value allocInt64 (ogg_int64_t val) {
		
		ogg_int32_t low = val;
		ogg_int32_t high = (val >> 32);
		
		_initializeVorbis ();
		
		alloc_field (int64Value, id_low, alloc_int (low));
		alloc_field (int64Value, id_high, alloc_int (high));
		
		return int64Value;
		
	}
	
	
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
		
		if (!val_is_null (vorbisFile)) {
			
			OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
			val_gc (vorbisFile, 0);
			ov_clear (file);
			
		}
		
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
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		vorbis_info *info = ov_info (file, bitstream);
		
		if (info) {
			
			_initializeVorbis ();
			
			alloc_field (infoValue, id_version, alloc_int (info->version));
			alloc_field (infoValue, id_channels, alloc_int (info->channels));
			alloc_field (infoValue, id_rate, alloc_int (info->rate));
			alloc_field (infoValue, id_bitrateUpper, alloc_int (info->bitrate_upper));
			alloc_field (infoValue, id_bitrateNominal, alloc_int (info->bitrate_nominal));
			alloc_field (infoValue, id_bitrateLower, alloc_int (info->bitrate_lower));
			
			return infoValue;
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_vorbis_file_from_bytes (value data) {
		
		Bytes bytes;
		bytes.Set (data);
		
		OggVorbis_File* vorbisFile = VorbisFile::FromBytes (&bytes);
		
		if (vorbisFile) {
			
			return CFFIPointer ((void*)(uintptr_t)vorbisFile, gc_vorbis_file);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_vorbis_file_from_file (HxString path) {
		
		OggVorbis_File* vorbisFile = VorbisFile::FromFile (path.c_str ());
		
		if (vorbisFile) {
			
			return CFFIPointer ((void*)(uintptr_t)vorbisFile, gc_vorbis_file);
			
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
	
	
	value lime_vorbis_file_read (value vorbisFile, value buffer, int position, int length, bool bigendianp, int word, bool sgned) {
		
		if (val_is_null (buffer)) {
			
			return alloc_null ();
			
		}
		
		Bytes bytes;
		bytes.Set (buffer);
		
		int bitstream;
		
		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		long result = ov_read (file, (char*)bytes.Data () + position, length, bigendianp, word, sgned, &bitstream);
		
		_initializeVorbis ();
		
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
	DEFINE_PRIME7 (lime_vorbis_file_read);
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