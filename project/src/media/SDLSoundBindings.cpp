#include <media/SDLSound.h>
#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <utils/Bytes.h>
#include <utils/Resource.h>


namespace lime {


	static int id_bitsPerSample;
	static int id_canSeek;
	static int id_channels;
	static int id_duration;
	static int id_sampleRate;
	static bool init = false;


	inline void _initializeSDLSound () {

		if (!init) {

			id_bitsPerSample = val_id ("bitsPerSample");
			id_canSeek = val_id ("canSeek");
			id_channels = val_id ("channels");
			id_duration = val_id ("duration");
			id_sampleRate = val_id ("sampleRate");

			init = true;

		}

	}


	inline void _hl_initializeSDLSound () {

		if (!init) {

			id_bitsPerSample = hl_hash_utf8 ("bitsPerSample");
			id_canSeek = hl_hash_utf8 ("canSeek");
			id_channels = hl_hash_utf8 ("channels");
			id_duration = hl_hash_utf8 ("duration");
			id_sampleRate = hl_hash_utf8 ("sampleRate");

			init = true;

		}

	}


	static value allocStreamInfo (const SDLSoundStreamInfo& streamInfo) {

		_initializeSDLSound ();

		value result = alloc_empty_object ();
		alloc_field (result, id_bitsPerSample, alloc_int (streamInfo.bitsPerSample));
		alloc_field (result, id_canSeek, alloc_bool (streamInfo.canSeek));
		alloc_field (result, id_channels, alloc_int (streamInfo.channels));
		alloc_field (result, id_duration, alloc_int (streamInfo.duration));
		alloc_field (result, id_sampleRate, alloc_int (streamInfo.sampleRate));
		return result;

	}


	static vdynamic* hl_allocStreamInfo (const SDLSoundStreamInfo& streamInfo) {

		_hl_initializeSDLSound ();

		vdynamic* result = (vdynamic*)hl_alloc_dynobj ();
		hl_dyn_seti (result, id_bitsPerSample, &hlt_i32, streamInfo.bitsPerSample);
		hl_dyn_seti (result, id_canSeek, &hlt_bool, streamInfo.canSeek);
		hl_dyn_seti (result, id_channels, &hlt_i32, streamInfo.channels);
		hl_dyn_seti (result, id_duration, &hlt_i32, streamInfo.duration);
		hl_dyn_seti (result, id_sampleRate, &hlt_i32, streamInfo.sampleRate);
		return result;

	}


	void lime_sdl_sound_stream_clear (value stream);
	HL_PRIM void HL_NAME(hl_sdl_sound_stream_clear) (HL_CFFIPointer* stream);


	void gc_sdl_sound_stream (value stream) {

		lime_sdl_sound_stream_clear (stream);

	}


	void hl_gc_sdl_sound_stream (HL_CFFIPointer* stream) {

		lime_hl_sdl_sound_stream_clear (stream);

	}


	value lime_sdl_sound_get_info_from_bytes (value data) {

		if (val_is_null (data)) {

			return alloc_null ();

		}

		Bytes bytes;
		bytes.Set (data);

		Resource resource (&bytes);
		SDLSoundStreamInfo streamInfo;

		if (SDLSound::GetStreamInfo (&resource, &streamInfo)) {

			return allocStreamInfo (streamInfo);

		}

		return alloc_null ();

	}


	HL_PRIM vdynamic* HL_NAME(hl_sdl_sound_get_info_from_bytes) (Bytes* data) {

		if (!data) {

			return NULL;

		}

		Resource resource (data);
		SDLSoundStreamInfo streamInfo;

		if (SDLSound::GetStreamInfo (&resource, &streamInfo)) {

			return hl_allocStreamInfo (streamInfo);

		}

		return NULL;

	}


	value lime_sdl_sound_get_info_from_file (HxString path) {

		Resource resource (path.c_str ());
		SDLSoundStreamInfo streamInfo;

		if (resource.path && SDLSound::GetStreamInfo (&resource, &streamInfo)) {

			return allocStreamInfo (streamInfo);

		}

		return alloc_null ();

	}


	HL_PRIM vdynamic* HL_NAME(hl_sdl_sound_get_info_from_file) (hl_vstring* path) {

		Resource resource (path);
		SDLSoundStreamInfo streamInfo;

		if (resource.path && SDLSound::GetStreamInfo (&resource, &streamInfo)) {

			return hl_allocStreamInfo (streamInfo);

		}

		return NULL;

	}


	value lime_sdl_sound_stream_from_bytes (value data) {

		if (val_is_null (data)) {

			return alloc_null ();

		}

		Bytes bytes;
		bytes.Set (data);

		Resource resource (&bytes);
		SDLSoundStream* stream = SDLSound::OpenStream (&resource);

		if (stream) {

			return CFFIPointer ((void*)(uintptr_t)stream, gc_sdl_sound_stream);

		}

		return alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_sdl_sound_stream_from_bytes) (Bytes* data) {

		if (!data) {

			return NULL;

		}

		Resource resource (data);
		SDLSoundStream* stream = SDLSound::OpenStream (&resource);

		if (stream) {

			return HLCFFIPointer ((void*)(uintptr_t)stream, (hl_finalizer)hl_gc_sdl_sound_stream);

		}

		return NULL;

	}


	value lime_sdl_sound_stream_from_file (HxString path) {

		Resource resource (path.c_str ());

		if (!resource.path) {

			return alloc_null ();

		}

		SDLSoundStream* stream = SDLSound::OpenStream (&resource);

		if (stream) {

			return CFFIPointer ((void*)(uintptr_t)stream, gc_sdl_sound_stream);

		}

		return alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_sdl_sound_stream_from_file) (hl_vstring* path) {

		Resource resource (path);

		if (!resource.path) {

			return NULL;

		}

		SDLSoundStream* stream = SDLSound::OpenStream (&resource);

		if (stream) {

			return HLCFFIPointer ((void*)(uintptr_t)stream, (hl_finalizer)hl_gc_sdl_sound_stream);

		}

		return NULL;

	}


	int lime_sdl_sound_stream_read (value stream, value buffer, int length) {

		if (val_is_null (stream) || val_is_null (buffer) || length <= 0) {

			return -1;

		}

		Bytes bytes;
		bytes.Set (buffer);

		if (length > bytes.length) {

			length = bytes.length;

		}

		SDLSoundStream* handle = (SDLSoundStream*)(uintptr_t)val_data (stream);
		return SDLSound::ReadStream (handle, bytes.b, length);

	}


	HL_PRIM int HL_NAME(hl_sdl_sound_stream_read) (HL_CFFIPointer* stream, Bytes* buffer, int length) {

		if (!stream || !buffer || length <= 0) {

			return -1;

		}

		if (length > buffer->length) {

			length = buffer->length;

		}

		SDLSoundStream* handle = (SDLSoundStream*)(uintptr_t)stream->ptr;
		return SDLSound::ReadStream (handle, buffer->b, length);

	}


	bool lime_sdl_sound_stream_rewind (value stream) {

		if (val_is_null (stream)) {

			return false;

		}

		SDLSoundStream* handle = (SDLSoundStream*)(uintptr_t)val_data (stream);
		return SDLSound::RewindStream (handle);

	}


	HL_PRIM bool HL_NAME(hl_sdl_sound_stream_rewind) (HL_CFFIPointer* stream) {

		if (!stream) {

			return false;

		}

		SDLSoundStream* handle = (SDLSoundStream*)(uintptr_t)stream->ptr;
		return SDLSound::RewindStream (handle);

	}


	bool lime_sdl_sound_stream_seek (value stream, int ms) {

		if (val_is_null (stream)) {

			return false;

		}

		SDLSoundStream* handle = (SDLSoundStream*)(uintptr_t)val_data (stream);
		return SDLSound::SeekStream (handle, ms);

	}


	HL_PRIM bool HL_NAME(hl_sdl_sound_stream_seek) (HL_CFFIPointer* stream, int ms) {

		if (!stream) {

			return false;

		}

		SDLSoundStream* handle = (SDLSoundStream*)(uintptr_t)stream->ptr;
		return SDLSound::SeekStream (handle, ms);

	}


	void lime_sdl_sound_stream_clear (value stream) {

		if (!val_is_null (stream)) {

			SDLSoundStream* handle = (SDLSoundStream*)(uintptr_t)val_data (stream);
			val_gc (stream, 0);
			SDLSound::CloseStream (handle);

		}

	}


	HL_PRIM void HL_NAME(hl_sdl_sound_stream_clear) (HL_CFFIPointer* stream) {

		if (stream) {

			SDLSoundStream* handle = (SDLSoundStream*)(uintptr_t)stream->ptr;
			stream->finalizer = 0;
			SDLSound::CloseStream (handle);

		}

	}


	DEFINE_PRIME1 (lime_sdl_sound_get_info_from_bytes);
	DEFINE_PRIME1 (lime_sdl_sound_get_info_from_file);
	DEFINE_PRIME1 (lime_sdl_sound_stream_from_bytes);
	DEFINE_PRIME1 (lime_sdl_sound_stream_from_file);
	DEFINE_PRIME3 (lime_sdl_sound_stream_read);
	DEFINE_PRIME1 (lime_sdl_sound_stream_rewind);
	DEFINE_PRIME2 (lime_sdl_sound_stream_seek);
	DEFINE_PRIME1v (lime_sdl_sound_stream_clear);


	#define _TBYTES _OBJ (_I32 _BYTES)
	#define _TCFFIPOINTER _DYN

	DEFINE_HL_PRIM (_DYN,          hl_sdl_sound_get_info_from_bytes, _TBYTES);
	DEFINE_HL_PRIM (_DYN,          hl_sdl_sound_get_info_from_file,  _STRING);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_sdl_sound_stream_from_bytes,   _TBYTES);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_sdl_sound_stream_from_file,    _STRING);
	DEFINE_HL_PRIM (_I32,          hl_sdl_sound_stream_read,         _TCFFIPOINTER _TBYTES _I32);
	DEFINE_HL_PRIM (_BOOL,         hl_sdl_sound_stream_rewind,       _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL,         hl_sdl_sound_stream_seek,         _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID,         hl_sdl_sound_stream_clear,        _TCFFIPOINTER);


}


extern "C" int lime_sdl_sound_register_prims () {

	return 0;

}
