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
	static vdynamic *hl_infoValue;
	static vdynamic *hl_int64Value;
	static vdynamic *hl_readValue;
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


	inline void _hl_initializeVorbis () {

		if (!init) {

			id_bitrateUpper = hl_hash_utf8 ("bitrateUpper");
			id_bitrateNominal = hl_hash_utf8 ("bitrateNominal");
			id_bitrateLower = hl_hash_utf8 ("bitrateLower");
			id_bitstream = hl_hash_utf8 ("bitstream");
			id_channels = hl_hash_utf8 ("channels");
			id_high = hl_hash_utf8 ("high");
			id_low = hl_hash_utf8 ("low");
			id_rate = hl_hash_utf8 ("rate");
			id_returnValue = hl_hash_utf8 ("returnValue");
			id_version = hl_hash_utf8 ("version");

			hl_infoValue = (vdynamic*)hl_alloc_dynobj();
			hl_int64Value = (vdynamic*)hl_alloc_dynobj();
			hl_readValue = (vdynamic*)hl_alloc_dynobj();

			hl_add_root(&hl_infoValue);
			hl_add_root(&hl_int64Value);
			hl_add_root(&hl_readValue);

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


	vdynamic* hl_allocInt64 (ogg_int64_t val) {

		ogg_int32_t low = val;
		ogg_int32_t high = (val >> 32);

		_hl_initializeVorbis ();

		hl_dyn_seti (hl_int64Value, id_low, &hlt_i32, low);
		hl_dyn_seti (hl_int64Value, id_high, &hlt_i32, high);

		return hl_int64Value;

	}


	void lime_vorbis_file_clear (value vorbisFile);
	HL_PRIM void HL_NAME(hl_vorbis_file_clear) (HL_CFFIPointer* vorbisFile);


	void gc_vorbis_file (value vorbisFile) {

		lime_vorbis_file_clear (vorbisFile);

	}

	void hl_gc_vorbis_file (HL_CFFIPointer* vorbisFile) {

		lime_hl_vorbis_file_clear (vorbisFile);

	}


	int lime_vorbis_file_bitrate (value vorbisFile, int bitstream) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_bitrate (file, bitstream);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_bitrate) (HL_CFFIPointer* vorbisFile, int bitstream) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return ov_bitrate (file, bitstream);

	}


	int lime_vorbis_file_bitrate_instant (value vorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_bitrate_instant (file);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_bitrate_instant) (HL_CFFIPointer* vorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return ov_bitrate_instant (file);

	}


	void lime_vorbis_file_clear (value vorbisFile) {

		if (!val_is_null (vorbisFile)) {

			OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
			val_gc (vorbisFile, 0);
			ov_clear (file);

		}

	}


	HL_PRIM void HL_NAME(hl_vorbis_file_clear) (HL_CFFIPointer* vorbisFile) {

		if (vorbisFile) {

			OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
			vorbisFile->finalizer = 0;
			ov_clear (file);

		}

	}


	value lime_vorbis_file_comment (value vorbisFile, int bitstream) {

		return alloc_null ();

	}


	HL_PRIM vdynamic* HL_NAME(hl_vorbis_file_comment) (HL_CFFIPointer* vorbisFile, int bitstream) {

		return NULL;

	}


	value lime_vorbis_file_crosslap (value vorbisFile, value otherVorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		OggVorbis_File* otherFile = (OggVorbis_File*)(uintptr_t)val_data (otherVorbisFile);
		return alloc_int (ov_crosslap (file, otherFile));

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_crosslap) (HL_CFFIPointer* vorbisFile, HL_CFFIPointer* otherVorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		OggVorbis_File* otherFile = (OggVorbis_File*)(uintptr_t)otherVorbisFile->ptr;
		return ov_crosslap (file, otherFile);

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


	HL_PRIM vdynamic* HL_NAME(hl_vorbis_file_info) (HL_CFFIPointer* vorbisFile, int bitstream) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		vorbis_info *info = ov_info (file, bitstream);

		if (info) {

			_hl_initializeVorbis ();

			hl_dyn_seti (hl_infoValue, id_version, &hlt_i32, info->version);
			hl_dyn_seti (hl_infoValue, id_channels, &hlt_i32, info->channels);
			hl_dyn_seti (hl_infoValue, id_rate, &hlt_i32, info->rate);
			hl_dyn_seti (hl_infoValue, id_bitrateUpper, &hlt_i32, info->bitrate_upper);
			hl_dyn_seti (hl_infoValue, id_bitrateNominal, &hlt_i32, info->bitrate_nominal);
			hl_dyn_seti (hl_infoValue, id_bitrateLower, &hlt_i32, info->bitrate_lower);

			return hl_infoValue;

		}

		return NULL;

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


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_vorbis_file_from_bytes) (Bytes* data) {

		OggVorbis_File* vorbisFile = VorbisFile::FromBytes (data);

		if (vorbisFile) {

			return HLCFFIPointer ((void*)(uintptr_t)vorbisFile, (hl_finalizer)hl_gc_vorbis_file);

		}

		return NULL;

	}


	value lime_vorbis_file_from_file (HxString path) {

		OggVorbis_File* vorbisFile = VorbisFile::FromFile (path.c_str ());

		if (vorbisFile) {

			return CFFIPointer ((void*)(uintptr_t)vorbisFile, gc_vorbis_file);

		}

		return alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_vorbis_file_from_file) (hl_vstring* path) {

		OggVorbis_File* vorbisFile = VorbisFile::FromFile (path ? hl_to_utf8 (path->bytes) : NULL);

		if (vorbisFile) {

			return HLCFFIPointer ((void*)(uintptr_t)vorbisFile, (hl_finalizer)hl_gc_vorbis_file);

		}

		return NULL;

	}


	int lime_vorbis_file_pcm_seek (value vorbisFile, value posLow, value posHigh) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ogg_int64_t pos = ((ogg_int64_t)val_number (posHigh) << 32) | (ogg_int64_t)val_number (posLow);
		return ov_pcm_seek (file, pos);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_pcm_seek) (HL_CFFIPointer* vorbisFile, int posLow, int posHigh) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		ogg_int64_t pos = ((ogg_int64_t)posHigh << 32) | (ogg_int64_t)posLow;
		return ov_pcm_seek (file, pos);

	}


	int lime_vorbis_file_pcm_seek_lap (value vorbisFile, value posLow, value posHigh) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ogg_int64_t pos = ((ogg_int64_t)val_number (posHigh) << 32) | (ogg_int64_t)val_number (posLow);
		return ov_pcm_seek_lap (file, pos);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_pcm_seek_lap) (HL_CFFIPointer* vorbisFile, int posLow, int posHigh) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		ogg_int64_t pos = ((ogg_int64_t)posHigh << 32) | (ogg_int64_t)posLow;
		return ov_pcm_seek_lap (file, pos);

	}


	int lime_vorbis_file_pcm_seek_page (value vorbisFile, value posLow, value posHigh) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ogg_int64_t pos = ((ogg_int64_t)val_number (posHigh) << 32) | (ogg_int64_t)val_number (posLow);
		return ov_pcm_seek_page (file, pos);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_pcm_seek_page) (HL_CFFIPointer* vorbisFile, int posLow, int posHigh) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		ogg_int64_t pos = ((ogg_int64_t)posHigh << 32) | (ogg_int64_t)posLow;
		return ov_pcm_seek_page (file, pos);

	}


	int lime_vorbis_file_pcm_seek_page_lap (value vorbisFile, value posLow, value posHigh) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ogg_int64_t pos = ((ogg_int64_t)val_number (posHigh) << 32) | (ogg_int64_t)val_number (posLow);
		return ov_pcm_seek_page_lap (file, pos);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_pcm_seek_page_lap) (HL_CFFIPointer* vorbisFile, int posLow, int posHigh) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		ogg_int64_t pos = ((ogg_int64_t)posHigh << 32) | (ogg_int64_t)posLow;
		return ov_pcm_seek_page_lap (file, pos);

	}


	value lime_vorbis_file_pcm_tell (value vorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return allocInt64 (ov_pcm_tell (file));

	}


	HL_PRIM vdynamic* HL_NAME(hl_vorbis_file_pcm_tell) (HL_CFFIPointer* vorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return hl_allocInt64 (ov_pcm_tell (file));

	}


	value lime_vorbis_file_pcm_total (value vorbisFile, int bitstream) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return allocInt64 (ov_pcm_total (file, bitstream));

	}


	HL_PRIM vdynamic* HL_NAME(hl_vorbis_file_pcm_total) (HL_CFFIPointer* vorbisFile, int bitstream) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return hl_allocInt64 (ov_pcm_total (file, bitstream));

	}


	int lime_vorbis_file_raw_seek (value vorbisFile, value posLow, value posHigh) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ogg_int64_t pos = ((ogg_int64_t)val_number (posHigh) << 32) | (ogg_int64_t)val_number (posLow);
		return ov_raw_seek (file, pos);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_raw_seek) (HL_CFFIPointer* vorbisFile, int posLow, int posHigh) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		ogg_int64_t pos = ((ogg_int64_t)posHigh << 32) | (ogg_int64_t)posLow;
		return ov_raw_seek (file, pos);

	}


	int lime_vorbis_file_raw_seek_lap (value vorbisFile, value posLow, value posHigh) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		ogg_int64_t pos = ((ogg_int64_t)val_number (posHigh) << 32) | (ogg_int64_t)val_number (posLow);
		return ov_raw_seek_lap (file, pos);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_raw_seek_lap) (HL_CFFIPointer* vorbisFile, int posLow, int posHigh) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		ogg_int64_t pos = ((ogg_int64_t)posHigh << 32) | (ogg_int64_t)posLow;
		return ov_raw_seek_lap (file, pos);

	}


	value lime_vorbis_file_raw_tell (value vorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return allocInt64 (ov_raw_tell (file));

	}


	HL_PRIM vdynamic* HL_NAME(hl_vorbis_file_raw_tell) (HL_CFFIPointer* vorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return hl_allocInt64 (ov_raw_tell (file));

	}


	value lime_vorbis_file_raw_total (value vorbisFile, int bitstream) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return allocInt64 (ov_raw_total (file, bitstream));

	}


	HL_PRIM vdynamic* HL_NAME(hl_vorbis_file_raw_total) (HL_CFFIPointer* vorbisFile, int bitstream) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return hl_allocInt64 (ov_raw_total (file, bitstream));

	}


	value lime_vorbis_file_read (value vorbisFile, value buffer, int position, int length, bool bigendianp, int word, bool sgned) {

		if (val_is_null (buffer)) {

			return alloc_null ();

		}

		Bytes bytes;
		bytes.Set (buffer);

		int bitstream;

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		long result = ov_read (file, (char*)bytes.b + position, length, bigendianp, word, sgned, &bitstream);

		_initializeVorbis ();

		alloc_field (readValue, id_bitstream, alloc_int (bitstream));
		alloc_field (readValue, id_returnValue, alloc_int (result));

		return readValue;

	}


	HL_PRIM vdynamic* HL_NAME(hl_vorbis_file_read) (HL_CFFIPointer* vorbisFile, Bytes* buffer, int position, int length, bool bigendianp, int word, bool sgned) {

		if (!buffer) {

			return NULL;

		}

		int bitstream;

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		long result = ov_read (file, (char*)buffer->b + position, length, bigendianp, word, sgned, &bitstream);

		_hl_initializeVorbis ();

		hl_dyn_seti (hl_readValue, id_bitstream, &hlt_i32, bitstream);
		hl_dyn_seti (hl_readValue, id_returnValue, &hlt_i32, result);

		return hl_readValue;

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


	HL_PRIM vdynamic* HL_NAME(hl_vorbis_file_read_float) (HL_CFFIPointer* vorbisFile, Bytes* pcmChannels, int samples) {

		return NULL;

	}


	bool lime_vorbis_file_seekable (value vorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_seekable (file);

	}


	HL_PRIM bool HL_NAME(hl_vorbis_file_seekable) (HL_CFFIPointer* vorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return ov_seekable (file);

	}


	int lime_vorbis_file_serial_number (value vorbisFile, int bitstream) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_serialnumber (file, bitstream);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_serial_number) (HL_CFFIPointer* vorbisFile, int bitstream) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return ov_serialnumber (file, bitstream);

	}


	int lime_vorbis_file_streams (value vorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_streams (file);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_streams) (HL_CFFIPointer* vorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return ov_streams (file);

	}


	int lime_vorbis_file_time_seek (value vorbisFile, double s) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_time_seek (file, s);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_time_seek) (HL_CFFIPointer* vorbisFile, double s) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return ov_time_seek (file, s);

	}


	int lime_vorbis_file_time_seek_lap (value vorbisFile, double s) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_time_seek_lap (file, s);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_time_seek_lap) (HL_CFFIPointer* vorbisFile, double s) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return ov_time_seek_lap (file, s);

	}


	int lime_vorbis_file_time_seek_page (value vorbisFile, double s) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_time_seek_page (file, s);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_time_seek_page) (HL_CFFIPointer* vorbisFile, double s) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return ov_time_seek_page (file, s);

	}


	int lime_vorbis_file_time_seek_page_lap (value vorbisFile, double s) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_time_seek_page_lap (file, s);

	}


	HL_PRIM int HL_NAME(hl_vorbis_file_time_seek_page_lap) (HL_CFFIPointer* vorbisFile, double s) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return ov_time_seek_page_lap (file, s);

	}


	double lime_vorbis_file_time_tell (value vorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_time_tell (file);

	}


	HL_PRIM double HL_NAME(hl_vorbis_file_time_tell) (HL_CFFIPointer* vorbisFile) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
		return ov_time_tell (file);

	}


	double lime_vorbis_file_time_total (value vorbisFile, int bitstream) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)val_data (vorbisFile);
		return ov_time_total (file, bitstream);

	}


	HL_PRIM double HL_NAME(hl_vorbis_file_time_total) (HL_CFFIPointer* vorbisFile, int bitstream) {

		OggVorbis_File* file = (OggVorbis_File*)(uintptr_t)vorbisFile->ptr;
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


	#define _TBYTES _OBJ (_I32 _BYTES)
	#define _TCFFIPOINTER _DYN

	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_bitrate,            _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_bitrate_instant,    _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID,         hl_vorbis_file_clear,              _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN,          hl_vorbis_file_comment,            _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_crosslap,           _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN,          hl_vorbis_file_info,               _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_vorbis_file_from_bytes,         _TBYTES);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_vorbis_file_from_file,          _STRING);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_pcm_seek,           _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_pcm_seek_lap,       _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_pcm_seek_page,      _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_pcm_seek_page_lap,  _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_DYN,          hl_vorbis_file_pcm_tell,           _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN,          hl_vorbis_file_pcm_total,          _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_raw_seek,           _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_raw_seek_lap,       _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_DYN,          hl_vorbis_file_raw_tell,           _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN,          hl_vorbis_file_raw_total,          _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_DYN,          hl_vorbis_file_read,               _TCFFIPOINTER _TBYTES _I32 _I32 _BOOL _I32 _BOOL);
	DEFINE_HL_PRIM (_DYN,          hl_vorbis_file_read_float,         _TCFFIPOINTER _TBYTES _I32);
	DEFINE_HL_PRIM (_BOOL,         hl_vorbis_file_seekable,           _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_serial_number,      _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_streams,            _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_time_seek,          _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_time_seek_lap,      _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_time_seek_page,     _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_I32,          hl_vorbis_file_time_seek_page_lap, _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_F64,          hl_vorbis_file_time_tell,          _TCFFIPOINTER);
	DEFINE_HL_PRIM (_F64,          hl_vorbis_file_time_total,         _TCFFIPOINTER _I32);


}


extern "C" int lime_vorbis_register_prims () {

	return 0;

}