#include <media/VoiceCapture.h>
#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <system/System.h>
#include <utils/Bytes.h>
#include <string>


namespace lime {


	void gc_voice_capture (value handle) {

		VoiceCapture* capture = (VoiceCapture*)val_data (handle);
		delete capture;

	}


	void hl_gc_voice_capture (HL_CFFIPointer* handle) {

		VoiceCapture* capture = (VoiceCapture*)handle->ptr;
		delete capture;

	}


	void lime_voice_capture_close (value handle) {

		VoiceCapture* capture = (VoiceCapture*)val_data (handle);

		System::GCEnterBlocking ();
		capture->Close ();
		System::GCExitBlocking ();

	}


	HL_PRIM void HL_NAME(hl_voice_capture_close) (HL_CFFIPointer* handle) {

		VoiceCapture* capture = (VoiceCapture*)handle->ptr;

		hl_blocking (true);
		capture->Close ();
		hl_blocking (false);

	}


	int lime_voice_capture_get_available (value handle) {

		VoiceCapture* capture = (VoiceCapture*)val_data (handle);
		return capture->GetAvailable ();

	}


	HL_PRIM int HL_NAME(hl_voice_capture_get_available) (HL_CFFIPointer* handle) {

		VoiceCapture* capture = (VoiceCapture*)handle->ptr;
		return capture->GetAvailable ();

	}


	int lime_voice_capture_get_processing (value handle) {

		VoiceCapture* capture = (VoiceCapture*)val_data (handle);
		return capture->GetProcessing ();

	}


	HL_PRIM int HL_NAME(hl_voice_capture_get_processing) (HL_CFFIPointer* handle) {

		VoiceCapture* capture = (VoiceCapture*)handle->ptr;
		return capture->GetProcessing ();

	}


	bool lime_voice_capture_is_connected (value handle) {

		VoiceCapture* capture = (VoiceCapture*)val_data (handle);
		return capture->IsConnected ();

	}


	HL_PRIM bool HL_NAME(hl_voice_capture_is_connected) (HL_CFFIPointer* handle) {

		VoiceCapture* capture = (VoiceCapture*)handle->ptr;
		return capture->IsConnected ();

	}


	value lime_voice_capture_open (HxString deviceName, int sampleRate, int channels, int bitsPerSample, int bufferFrames, int processing) {

		// hxcpp keeps strings with non-ASCII characters as UTF-16
		const char* utf8 = hxs_utf8 (deviceName, nullptr);
		std::string name = utf8 ? utf8 : "";

		// Opening a device can take a moment
		System::GCEnterBlocking ();
		VoiceCapture* capture = VoiceCapture::Open (name.empty () ? NULL : name.c_str (), sampleRate, channels, bitsPerSample, bufferFrames, processing);
		System::GCExitBlocking ();

		if (!capture) return alloc_null ();
		return CFFIPointer (capture, gc_voice_capture);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_voice_capture_open) (hl_vstring* deviceName, int sampleRate, int channels, int bitsPerSample, int bufferFrames, int processing) {

		std::string name = deviceName ? hl_to_utf8 (deviceName->bytes) : "";

		hl_blocking (true);
		VoiceCapture* capture = VoiceCapture::Open (name.empty () ? NULL : name.c_str (), sampleRate, channels, bitsPerSample, bufferFrames, processing);
		hl_blocking (false);

		if (!capture) return NULL;
		return HLCFFIPointer (capture, (hl_finalizer)hl_gc_voice_capture);

	}


	int lime_voice_capture_read (value handle, value buffer, int frames) {

		VoiceCapture* capture = (VoiceCapture*)val_data (handle);
		Bytes bytes (buffer);
		return capture->Read (bytes.b, frames);

	}


	HL_PRIM int HL_NAME(hl_voice_capture_read) (HL_CFFIPointer* handle, Bytes* buffer, int frames) {

		VoiceCapture* capture = (VoiceCapture*)handle->ptr;
		return capture->Read (buffer->b, frames);

	}


	bool lime_voice_capture_start (value handle) {

		VoiceCapture* capture = (VoiceCapture*)val_data (handle);
		return capture->Start ();

	}


	HL_PRIM bool HL_NAME(hl_voice_capture_start) (HL_CFFIPointer* handle) {

		VoiceCapture* capture = (VoiceCapture*)handle->ptr;
		return capture->Start ();

	}


	void lime_voice_capture_stop (value handle) {

		VoiceCapture* capture = (VoiceCapture*)val_data (handle);
		capture->Stop ();

	}


	HL_PRIM void HL_NAME(hl_voice_capture_stop) (HL_CFFIPointer* handle) {

		VoiceCapture* capture = (VoiceCapture*)handle->ptr;
		capture->Stop ();

	}


	DEFINE_PRIME1v (lime_voice_capture_close);
	DEFINE_PRIME1 (lime_voice_capture_get_available);
	DEFINE_PRIME1 (lime_voice_capture_get_processing);
	DEFINE_PRIME1 (lime_voice_capture_is_connected);
	DEFINE_PRIME6 (lime_voice_capture_open);
	DEFINE_PRIME3 (lime_voice_capture_read);
	DEFINE_PRIME1 (lime_voice_capture_start);
	DEFINE_PRIME1v (lime_voice_capture_stop);


	#define _TBYTES _OBJ (_I32 _BYTES)
	#define _TCFFIPOINTER _DYN

	DEFINE_HL_PRIM (_VOID, hl_voice_capture_close, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_voice_capture_get_available, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_voice_capture_get_processing, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_voice_capture_is_connected, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_voice_capture_open, _STRING _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_voice_capture_read, _TCFFIPOINTER _TBYTES _I32);
	DEFINE_HL_PRIM (_BOOL, hl_voice_capture_start, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_voice_capture_stop, _TCFFIPOINTER);


}


extern "C" int lime_voice_capture_register_prims () {

	return 0;

}
