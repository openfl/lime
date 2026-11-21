#include <media/CameraCapture.h>
#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <system/System.h>
#include <utils/Bytes.h>
#include <string.h>
#include <string>


namespace lime {


	// What lime_camera_capture_get_property reads
	enum CameraCaptureProperty {

		CAMERA_PROPERTY_WIDTH = 0,
		CAMERA_PROPERTY_HEIGHT = 1,
		CAMERA_PROPERTY_FRAME_RATE = 2,
		CAMERA_PROPERTY_FRAME_WIDTH = 3,
		CAMERA_PROPERTY_FRAME_HEIGHT = 4,
		CAMERA_PROPERTY_FRAME_LENGTH = 5,
		CAMERA_PROPERTY_FRAME_COLOR_MATRIX = 6,
		CAMERA_PROPERTY_FRAME_FULL_RANGE = 7,
		CAMERA_PROPERTY_FRAME_TIME = 8

	};


	// One record per camera, its id, name and position split by 0x1F, and the
	// records by 0x1E, so every target reads the list the same way
	static bool GetCameraDevices (std::string* result) {

		std::vector<CameraDeviceInfo> devices;
		if (!CameraCapture::GetDevices (&devices)) return false;

		for (size_t i = 0; i < devices.size (); i++) {

			if (i > 0) *result += '\x1E';
			*result += devices[i].id;
			*result += '\x1F';
			*result += devices[i].name;
			*result += '\x1F';
			*result += (char)('0' + (int)devices[i].position);

		}

		return true;

	}


	static double GetCameraProperty (CameraCapture* capture, int property) {

		switch (property) {

			case CAMERA_PROPERTY_WIDTH: return capture->width;
			case CAMERA_PROPERTY_HEIGHT: return capture->height;
			case CAMERA_PROPERTY_FRAME_RATE: return capture->frameRate;
			case CAMERA_PROPERTY_FRAME_WIDTH: return capture->frameWidth;
			case CAMERA_PROPERTY_FRAME_HEIGHT: return capture->frameHeight;
			case CAMERA_PROPERTY_FRAME_LENGTH: return capture->frameLength;
			case CAMERA_PROPERTY_FRAME_COLOR_MATRIX: return capture->frameColorMatrix;
			case CAMERA_PROPERTY_FRAME_FULL_RANGE: return capture->frameFullRange ? 1 : 0;
			case CAMERA_PROPERTY_FRAME_TIME: return capture->frameTime;
			default: return 0;

		}

	}


	void gc_camera_capture (value handle) {

		CameraCapture* capture = (CameraCapture*)val_data (handle);
		delete capture;

	}


	void hl_gc_camera_capture (HL_CFFIPointer* handle) {

		CameraCapture* capture = (CameraCapture*)handle->ptr;
		delete capture;

	}


	void lime_camera_capture_close (value handle) {

		CameraCapture* capture = (CameraCapture*)val_data (handle);

		System::GCEnterBlocking ();
		capture->Close ();
		System::GCExitBlocking ();

	}


	HL_PRIM void HL_NAME(hl_camera_capture_close) (HL_CFFIPointer* handle) {

		CameraCapture* capture = (CameraCapture*)handle->ptr;

		hl_blocking (true);
		capture->Close ();
		hl_blocking (false);

	}


	value lime_camera_capture_get_devices () {

		std::string devices;

		// Listing the cameras can take a moment
		System::GCEnterBlocking ();
		bool listed = GetCameraDevices (&devices);
		System::GCExitBlocking ();

		if (!listed) return alloc_null ();
		return alloc_string_len (devices.c_str (), (int)devices.size ());

	}


	HL_PRIM vbyte* HL_NAME(hl_camera_capture_get_devices) () {

		std::string devices;

		hl_blocking (true);
		bool listed = GetCameraDevices (&devices);
		hl_blocking (false);

		if (!listed) return NULL;

		vbyte* result = hl_alloc_bytes ((int)devices.size () + 1);
		memcpy (result, devices.c_str (), devices.size () + 1);
		return result;

	}


	int lime_camera_capture_get_permission_status () {

		return CameraCapture::GetPermissionStatus ();

	}


	HL_PRIM int HL_NAME(hl_camera_capture_get_permission_status) () {

		return CameraCapture::GetPermissionStatus ();

	}


	double lime_camera_capture_get_property (value handle, int property) {

		CameraCapture* capture = (CameraCapture*)val_data (handle);
		return GetCameraProperty (capture, property);

	}


	HL_PRIM double HL_NAME(hl_camera_capture_get_property) (HL_CFFIPointer* handle, int property) {

		CameraCapture* capture = (CameraCapture*)handle->ptr;
		return GetCameraProperty (capture, property);

	}


	bool lime_camera_capture_is_connected (value handle) {

		CameraCapture* capture = (CameraCapture*)val_data (handle);
		return capture->IsConnected ();

	}


	HL_PRIM bool HL_NAME(hl_camera_capture_is_connected) (HL_CFFIPointer* handle) {

		CameraCapture* capture = (CameraCapture*)handle->ptr;
		return capture->IsConnected ();

	}


	bool lime_camera_capture_is_supported () {

		return CameraCapture::IsSupported ();

	}


	HL_PRIM bool HL_NAME(hl_camera_capture_is_supported) () {

		return CameraCapture::IsSupported ();

	}


	value lime_camera_capture_open (HxString id, int width, int height, double frameRate) {

		// hxcpp keeps strings with non-ASCII characters as UTF-16
		const char* utf8 = hxs_utf8 (id, nullptr);
		std::string device = utf8 ? utf8 : "";

		// Opening a camera can take a moment
		System::GCEnterBlocking ();
		CameraCapture* capture = CameraCapture::Open (device.empty () ? NULL : device.c_str (), width, height, frameRate);
		System::GCExitBlocking ();

		if (!capture) return alloc_null ();
		return CFFIPointer (capture, gc_camera_capture);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_camera_capture_open) (hl_vstring* id, int width, int height, double frameRate) {

		std::string device = id ? hl_to_utf8 (id->bytes) : "";

		hl_blocking (true);
		CameraCapture* capture = CameraCapture::Open (device.empty () ? NULL : device.c_str (), width, height, frameRate);
		hl_blocking (false);

		if (!capture) return NULL;
		return HLCFFIPointer (capture, (hl_finalizer)hl_gc_camera_capture);

	}


	int lime_camera_capture_read_frame (value handle, int format, value buffer, int position, int length) {

		CameraCapture* capture = (CameraCapture*)val_data (handle);
		Bytes bytes (buffer);

		if (!bytes.b || position < 0 || length < 0 || position > bytes.length || length > bytes.length - position) {

			return capture->ReadFrame ((VideoFrameFormat)format, NULL, 0);

		}

		return capture->ReadFrame ((VideoFrameFormat)format, bytes.b + position, length);

	}


	HL_PRIM int HL_NAME(hl_camera_capture_read_frame) (HL_CFFIPointer* handle, int format, Bytes* buffer, int position, int length) {

		CameraCapture* capture = (CameraCapture*)handle->ptr;

		if (!buffer || !buffer->b || position < 0 || length < 0 || position > buffer->length || length > buffer->length - position) {

			return capture->ReadFrame ((VideoFrameFormat)format, NULL, 0);

		}

		return capture->ReadFrame ((VideoFrameFormat)format, buffer->b + position, length);

	}


	void lime_camera_capture_request_permission () {

		CameraCapture::RequestPermission ();

	}


	HL_PRIM void HL_NAME(hl_camera_capture_request_permission) () {

		CameraCapture::RequestPermission ();

	}


	bool lime_camera_capture_start (value handle) {

		CameraCapture* capture = (CameraCapture*)val_data (handle);
		return capture->Start ();

	}


	HL_PRIM bool HL_NAME(hl_camera_capture_start) (HL_CFFIPointer* handle) {

		CameraCapture* capture = (CameraCapture*)handle->ptr;
		return capture->Start ();

	}


	void lime_camera_capture_stop (value handle) {

		CameraCapture* capture = (CameraCapture*)val_data (handle);
		capture->Stop ();

	}


	HL_PRIM void HL_NAME(hl_camera_capture_stop) (HL_CFFIPointer* handle) {

		CameraCapture* capture = (CameraCapture*)handle->ptr;
		capture->Stop ();

	}


	DEFINE_PRIME1v (lime_camera_capture_close);
	DEFINE_PRIME0 (lime_camera_capture_get_devices);
	DEFINE_PRIME0 (lime_camera_capture_get_permission_status);
	DEFINE_PRIME2 (lime_camera_capture_get_property);
	DEFINE_PRIME1 (lime_camera_capture_is_connected);
	DEFINE_PRIME0 (lime_camera_capture_is_supported);
	DEFINE_PRIME4 (lime_camera_capture_open);
	DEFINE_PRIME5 (lime_camera_capture_read_frame);
	DEFINE_PRIME0v (lime_camera_capture_request_permission);
	DEFINE_PRIME1 (lime_camera_capture_start);
	DEFINE_PRIME1v (lime_camera_capture_stop);


	#define _TBYTES _OBJ (_I32 _BYTES)
	#define _TCFFIPOINTER _DYN

	DEFINE_HL_PRIM (_VOID, hl_camera_capture_close, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BYTES, hl_camera_capture_get_devices, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_camera_capture_get_permission_status, _NO_ARG);
	DEFINE_HL_PRIM (_F64, hl_camera_capture_get_property, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_BOOL, hl_camera_capture_is_connected, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_camera_capture_is_supported, _NO_ARG);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_camera_capture_open, _STRING _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_camera_capture_read_frame, _TCFFIPOINTER _I32 _TBYTES _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_camera_capture_request_permission, _NO_ARG);
	DEFINE_HL_PRIM (_BOOL, hl_camera_capture_start, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_camera_capture_stop, _TCFFIPOINTER);


}


extern "C" int lime_camera_capture_register_prims () {

	return 0;

}
