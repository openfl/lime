#include <media/VideoDecoder.h>
#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <system/System.h>
#include <utils/Bytes.h>
#include <string>


namespace lime {


	static int id_audioChannels;
	static int id_audioSampleRate;
	static int id_colorMatrix;
	static int id_duration;
	static int id_frameRate;
	static int id_fullRange;
	static int id_hasAudio;
	static int id_hasVideo;
	static int id_height;
	static int id_length;
	static int id_texture;
	static int id_time;
	static int id_width;
	static bool init = false;
	static bool hl_init = false;


	inline void _initializeVideo () {

		if (!init) {

			id_audioChannels = val_id ("audioChannels");
			id_audioSampleRate = val_id ("audioSampleRate");
			id_colorMatrix = val_id ("colorMatrix");
			id_duration = val_id ("duration");
			id_frameRate = val_id ("frameRate");
			id_fullRange = val_id ("fullRange");
			id_hasAudio = val_id ("hasAudio");
			id_hasVideo = val_id ("hasVideo");
			id_height = val_id ("height");
			id_length = val_id ("length");
			id_texture = val_id ("texture");
			id_time = val_id ("time");
			id_width = val_id ("width");
			init = true;

		}

	}


	inline void _hl_initializeVideo () {

		if (!hl_init) {

			id_audioChannels = hl_hash_utf8 ("audioChannels");
			id_audioSampleRate = hl_hash_utf8 ("audioSampleRate");
			id_colorMatrix = hl_hash_utf8 ("colorMatrix");
			id_duration = hl_hash_utf8 ("duration");
			id_frameRate = hl_hash_utf8 ("frameRate");
			id_fullRange = hl_hash_utf8 ("fullRange");
			id_hasAudio = hl_hash_utf8 ("hasAudio");
			id_hasVideo = hl_hash_utf8 ("hasVideo");
			id_height = hl_hash_utf8 ("height");
			id_length = hl_hash_utf8 ("length");
			id_texture = hl_hash_utf8 ("texture");
			id_time = hl_hash_utf8 ("time");
			id_width = hl_hash_utf8 ("width");
			hl_init = true;

		}

	}


	void gc_video_decoder (value handle) {

		VideoDecoder* decoder = (VideoDecoder*)val_data (handle);
		delete decoder;

	}


	void hl_gc_video_decoder (HL_CFFIPointer* handle) {

		VideoDecoder* decoder = (VideoDecoder*)handle->ptr;
		delete decoder;

	}


	void lime_video_decoder_close (value handle) {

		VideoDecoder* decoder = (VideoDecoder*)val_data (handle);

		System::GCEnterBlocking ();
		decoder->Close ();
		System::GCExitBlocking ();

	}


	HL_PRIM void HL_NAME(hl_video_decoder_close) (HL_CFFIPointer* handle) {

		VideoDecoder* decoder = (VideoDecoder*)handle->ptr;

		hl_blocking (true);
		decoder->Close ();
		hl_blocking (false);

	}


	value lime_video_decoder_create () {

		VideoBackend* backend = VideoBackend::Create ();
		if (!backend) return alloc_null ();

		VideoDecoder* decoder = new VideoDecoder (backend);
		return CFFIPointer (decoder, gc_video_decoder);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_video_decoder_create) () {

		VideoBackend* backend = VideoBackend::Create ();
		if (!backend) return NULL;

		VideoDecoder* decoder = new VideoDecoder (backend);
		return HLCFFIPointer (decoder, (hl_finalizer)hl_gc_video_decoder);

	}


	double lime_video_decoder_get_audio_time (value handle) {

		VideoDecoder* decoder = (VideoDecoder*)val_data (handle);
		return decoder->audioTime;

	}


	HL_PRIM double HL_NAME(hl_video_decoder_get_audio_time) (HL_CFFIPointer* handle) {

		VideoDecoder* decoder = (VideoDecoder*)handle->ptr;
		return decoder->audioTime;

	}


	value lime_video_decoder_get_frame_info (value handle) {

		VideoDecoder* decoder = (VideoDecoder*)val_data (handle);

		_initializeVideo ();

		value info = alloc_empty_object ();
		alloc_field (info, id_colorMatrix, alloc_int (decoder->frameColorMatrix));
		alloc_field (info, id_duration, alloc_float (decoder->frameDuration));
		alloc_field (info, id_fullRange, alloc_bool (decoder->frameFullRange));
		alloc_field (info, id_height, alloc_int (decoder->frameHeight));
		alloc_field (info, id_length, alloc_int (decoder->frameLength));
		alloc_field (info, id_texture, alloc_int (decoder->frameTexture));
		alloc_field (info, id_time, alloc_float (decoder->frameTime));
		alloc_field (info, id_width, alloc_int (decoder->frameWidth));
		return info;

	}


	HL_PRIM vdynamic* HL_NAME(hl_video_decoder_get_frame_info) (HL_CFFIPointer* handle) {

		VideoDecoder* decoder = (VideoDecoder*)handle->ptr;

		_hl_initializeVideo ();

		vdynamic* info = (vdynamic*)hl_alloc_dynobj ();
		hl_dyn_seti (info, id_colorMatrix, &hlt_i32, decoder->frameColorMatrix);
		hl_dyn_setd (info, id_duration, decoder->frameDuration);
		hl_dyn_seti (info, id_fullRange, &hlt_bool, decoder->frameFullRange);
		hl_dyn_seti (info, id_height, &hlt_i32, decoder->frameHeight);
		hl_dyn_seti (info, id_length, &hlt_i32, decoder->frameLength);
		hl_dyn_seti (info, id_texture, &hlt_i32, decoder->frameTexture);
		hl_dyn_setd (info, id_time, decoder->frameTime);
		hl_dyn_seti (info, id_width, &hlt_i32, decoder->frameWidth);
		return info;

	}


	bool lime_video_decoder_is_supported () {

		return VideoBackend::IsSupported ();

	}


	HL_PRIM bool HL_NAME(hl_video_decoder_is_supported) () {

		return VideoBackend::IsSupported ();

	}


	value lime_video_decoder_open (value handle, HxString path, bool hardwareDecoding, int format) {

		VideoDecoder* decoder = (VideoDecoder*)val_data (handle);
		std::string source = path.c_str () ? path.c_str () : "";

		System::GCEnterBlocking ();
		bool success = decoder->Open (source.c_str (), hardwareDecoding, (VideoFrameFormat)format);
		System::GCExitBlocking ();

		if (!success) return alloc_null ();

		_initializeVideo ();

		value info = alloc_empty_object ();
		alloc_field (info, id_audioChannels, alloc_int (decoder->info.audioChannels));
		alloc_field (info, id_audioSampleRate, alloc_int (decoder->info.audioSampleRate));
		alloc_field (info, id_duration, alloc_float (decoder->info.duration));
		alloc_field (info, id_frameRate, alloc_float (decoder->info.frameRate));
		alloc_field (info, id_hasAudio, alloc_bool (decoder->info.hasAudio));
		alloc_field (info, id_hasVideo, alloc_bool (decoder->info.hasVideo));
		alloc_field (info, id_height, alloc_int (decoder->info.height));
		alloc_field (info, id_width, alloc_int (decoder->info.width));
		return info;

	}


	HL_PRIM vdynamic* HL_NAME(hl_video_decoder_open) (HL_CFFIPointer* handle, hl_vstring* path, bool hardwareDecoding, int format) {

		VideoDecoder* decoder = (VideoDecoder*)handle->ptr;
		std::string source = path ? hl_to_utf8 (path->bytes) : "";

		hl_blocking (true);
		bool success = decoder->Open (source.c_str (), hardwareDecoding, (VideoFrameFormat)format);
		hl_blocking (false);

		if (!success) return NULL;

		_hl_initializeVideo ();

		vdynamic* info = (vdynamic*)hl_alloc_dynobj ();
		hl_dyn_seti (info, id_audioChannels, &hlt_i32, decoder->info.audioChannels);
		hl_dyn_seti (info, id_audioSampleRate, &hlt_i32, decoder->info.audioSampleRate);
		hl_dyn_setd (info, id_duration, decoder->info.duration);
		hl_dyn_setd (info, id_frameRate, decoder->info.frameRate);
		hl_dyn_seti (info, id_hasAudio, &hlt_bool, decoder->info.hasAudio);
		hl_dyn_seti (info, id_hasVideo, &hlt_bool, decoder->info.hasVideo);
		hl_dyn_seti (info, id_height, &hlt_i32, decoder->info.height);
		hl_dyn_seti (info, id_width, &hlt_i32, decoder->info.width);
		return info;

	}


	int lime_video_decoder_read_audio (value handle, value buffer, int position, int length) {

		VideoDecoder* decoder = (VideoDecoder*)val_data (handle);
		Bytes bytes (buffer);

		if (!bytes.b || position < 0 || length < 0 || position + length > bytes.length) return VIDEO_READ_ERROR;

		return decoder->ReadAudio (bytes.b + position, length);

	}


	HL_PRIM int HL_NAME(hl_video_decoder_read_audio) (HL_CFFIPointer* handle, Bytes* buffer, int position, int length) {

		VideoDecoder* decoder = (VideoDecoder*)handle->ptr;

		if (!buffer || !buffer->b || position < 0 || length < 0 || position + length > buffer->length) return VIDEO_READ_ERROR;

		return decoder->ReadAudio (buffer->b + position, length);

	}


	int lime_video_decoder_read_frame (value handle, value buffer, int position, int length, double time) {

		VideoDecoder* decoder = (VideoDecoder*)val_data (handle);
		Bytes bytes (buffer);

		if (!bytes.b || position < 0 || length < 0 || position + length > bytes.length) {

			return decoder->ReadFrame (NULL, 0, time);

		}

		return decoder->ReadFrame (bytes.b + position, length, time);

	}


	HL_PRIM int HL_NAME(hl_video_decoder_read_frame) (HL_CFFIPointer* handle, Bytes* buffer, int position, int length, double time) {

		VideoDecoder* decoder = (VideoDecoder*)handle->ptr;

		if (!buffer || !buffer->b || position < 0 || length < 0 || position + length > buffer->length) {

			return decoder->ReadFrame (NULL, 0, time);

		}

		return decoder->ReadFrame (buffer->b + position, length, time);

	}


	void lime_video_decoder_seek (value handle, double time, bool accurate) {

		VideoDecoder* decoder = (VideoDecoder*)val_data (handle);

		System::GCEnterBlocking ();
		decoder->Seek (time, accurate);
		System::GCExitBlocking ();

	}


	HL_PRIM void HL_NAME(hl_video_decoder_seek) (HL_CFFIPointer* handle, double time, bool accurate) {

		VideoDecoder* decoder = (VideoDecoder*)handle->ptr;

		hl_blocking (true);
		decoder->Seek (time, accurate);
		hl_blocking (false);

	}


	DEFINE_PRIME1v (lime_video_decoder_close);
	DEFINE_PRIME0 (lime_video_decoder_create);
	DEFINE_PRIME1 (lime_video_decoder_get_audio_time);
	DEFINE_PRIME1 (lime_video_decoder_get_frame_info);
	DEFINE_PRIME0 (lime_video_decoder_is_supported);
	DEFINE_PRIME4 (lime_video_decoder_open);
	DEFINE_PRIME4 (lime_video_decoder_read_audio);
	DEFINE_PRIME5 (lime_video_decoder_read_frame);
	DEFINE_PRIME3v (lime_video_decoder_seek);


	#define _TBYTES _OBJ (_I32 _BYTES)
	#define _TCFFIPOINTER _DYN

	DEFINE_HL_PRIM (_VOID, hl_video_decoder_close, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_video_decoder_create, _NO_ARG);
	DEFINE_HL_PRIM (_F64, hl_video_decoder_get_audio_time, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN, hl_video_decoder_get_frame_info, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_video_decoder_is_supported, _NO_ARG);
	DEFINE_HL_PRIM (_DYN, hl_video_decoder_open, _TCFFIPOINTER _STRING _BOOL _I32);
	DEFINE_HL_PRIM (_I32, hl_video_decoder_read_audio, _TCFFIPOINTER _TBYTES _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_video_decoder_read_frame, _TCFFIPOINTER _TBYTES _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_video_decoder_seek, _TCFFIPOINTER _F64 _BOOL);


}


extern "C" int lime_video_register_prims () {

	return 0;

}
