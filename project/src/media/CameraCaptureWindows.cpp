#if defined (HX_WINDOWS) && !defined (HX_WINRT)

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#if !defined (_WIN32_WINNT) || _WIN32_WINNT < 0x0602
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0602
#endif

#include <windows.h>
#include <initguid.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mferror.h>
#include <mfreadwrite.h>
#include <atomic>
#include <condition_variable>
#include <functional>
#include <math.h>
#include <stdlib.h>
#include <thread>

#include <media/CameraCapture.h>


namespace lime {


	typedef HRESULT (WINAPI *CameraMFStartupFunc) (ULONG, DWORD);
	typedef HRESULT (WINAPI *CameraMFShutdownFunc) ();
	typedef HRESULT (WINAPI *CameraMFCreateAttributesFunc) (IMFAttributes**, UINT32);
	typedef HRESULT (WINAPI *CameraMFCreateMediaTypeFunc) (IMFMediaType**);
	typedef HRESULT (WINAPI *CameraMFEnumDeviceSourcesFunc) (IMFAttributes*, IMFActivate***, UINT32*);
	typedef HRESULT (WINAPI *CameraMFCreateSourceReaderFromMediaSourceFunc) (IMFMediaSource*, IMFAttributes*, IMFSourceReader**);

	static CameraMFStartupFunc cameraMFStartup = NULL;
	static CameraMFShutdownFunc cameraMFShutdown = NULL;
	static CameraMFCreateAttributesFunc cameraMFCreateAttributes = NULL;
	static CameraMFCreateMediaTypeFunc cameraMFCreateMediaType = NULL;
	static CameraMFEnumDeviceSourcesFunc cameraMFEnumDeviceSources = NULL;
	static CameraMFCreateSourceReaderFromMediaSourceFunc cameraMFCreateSourceReaderFromMediaSource = NULL;
	static std::once_flag cameraLoadFlag;
	static bool cameraLoaded = false;


	static HMODULE LoadCameraSystemLibrary (const wchar_t* name) {

		// From the system directory only, so a DLL of the same name beside the
		// application is not loaded instead
		wchar_t path[MAX_PATH];
		UINT length = GetSystemDirectoryW (path, MAX_PATH);
		if (length == 0 || length + wcslen (name) + 2 > MAX_PATH) return NULL;

		path[length] = L'\\';
		wcscpy (path + length + 1, name);
		return LoadLibraryW (path);

	}


	// Media Foundation is loaded when it is first needed, as for video, so Lime
	// still starts on Windows editions without it
	static bool LoadCameraMediaFoundation () {

		std::call_once (cameraLoadFlag, [] {

			HMODULE mfplat = LoadCameraSystemLibrary (L"mfplat.dll");
			HMODULE mf = LoadCameraSystemLibrary (L"mf.dll");
			HMODULE mfreadwrite = LoadCameraSystemLibrary (L"mfreadwrite.dll");
			if (!mfplat || !mf || !mfreadwrite) return;

			cameraMFStartup = (CameraMFStartupFunc)GetProcAddress (mfplat, "MFStartup");
			cameraMFShutdown = (CameraMFShutdownFunc)GetProcAddress (mfplat, "MFShutdown");
			cameraMFCreateAttributes = (CameraMFCreateAttributesFunc)GetProcAddress (mfplat, "MFCreateAttributes");
			cameraMFCreateMediaType = (CameraMFCreateMediaTypeFunc)GetProcAddress (mfplat, "MFCreateMediaType");
			cameraMFEnumDeviceSources = (CameraMFEnumDeviceSourcesFunc)GetProcAddress (mf, "MFEnumDeviceSources");
			cameraMFCreateSourceReaderFromMediaSource = (CameraMFCreateSourceReaderFromMediaSourceFunc)GetProcAddress (mfreadwrite, "MFCreateSourceReaderFromMediaSource");

			cameraLoaded = cameraMFStartup && cameraMFShutdown && cameraMFCreateAttributes && cameraMFCreateMediaType && cameraMFEnumDeviceSources && cameraMFCreateSourceReaderFromMediaSource;

		});

		return cameraLoaded;

	}


	template<class T> static void CameraRelease (T** object) {

		if (*object) {

			(*object)->Release ();
			*object = NULL;

		}

	}


	// Media Foundation runs in its own apartment, whatever the application's main
	// thread uses
	static void RunInMediaFoundation (std::function<void ()> work) {

		std::thread thread ([&work] {

			HRESULT result = CoInitializeEx (NULL, COINIT_MULTITHREADED);
			bool started = SUCCEEDED (cameraMFStartup (MF_VERSION, MFSTARTUP_LITE));
			if (started) work ();
			if (started) cameraMFShutdown ();
			if (SUCCEEDED (result)) CoUninitialize ();

		});

		thread.join ();

	}


	static std::string CameraToUTF8 (const wchar_t* text) {

		if (!text || !text[0]) return "";

		int length = WideCharToMultiByte (CP_UTF8, 0, text, -1, NULL, 0, NULL, NULL);
		if (length <= 1) return "";

		std::string result (length - 1, '\0');
		WideCharToMultiByte (CP_UTF8, 0, text, -1, &result[0], length, NULL, NULL);
		return result;

	}


	static std::string GetActivateString (IMFActivate* activate, REFGUID key) {

		WCHAR* value = NULL;
		UINT32 length = 0;
		if (FAILED (activate->GetAllocatedString (key, &value, &length))) return "";

		std::string result = CameraToUTF8 (value);
		CoTaskMemFree (value);
		return result;

	}


	// The cameras, each with its activation object, which the caller releases
	static bool EnumerateCameras (IMFActivate*** devices, UINT32* count) {

		IMFAttributes* attributes = NULL;
		if (FAILED (cameraMFCreateAttributes (&attributes, 1))) return false;

		bool success = SUCCEEDED (attributes->SetGUID (MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE, MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID)) && SUCCEEDED (cameraMFEnumDeviceSources (attributes, devices, count));
		attributes->Release ();
		return success;

	}


	class MFCameraCapture : public CameraCapture {


		public:

			MFCameraCapture () {

				opened = false;
				quit = false;
				ready = false;
				running = false;

			}


			~MFCameraCapture () {

				Close ();

			}


			void Close () {

				{
					std::lock_guard<std::mutex> lock (stateMutex);
					quit = true;
					stateCondition.notify_all ();
				}

				if (thread.joinable ()) thread.join ();
				SetDisconnected ();

			}


			bool Open (const char* id, int requestedWidth, int requestedHeight, double requestedFrameRate) {

				std::string device = id ? id : "";
				thread = std::thread ([this, device, requestedWidth, requestedHeight, requestedFrameRate] { Run (device, requestedWidth, requestedHeight, requestedFrameRate); });

				std::unique_lock<std::mutex> lock (stateMutex);
				stateCondition.wait (lock, [this] { return ready; });
				return opened;

			}


			bool Start () {

				std::lock_guard<std::mutex> lock (stateMutex);
				running = true;
				stateCondition.notify_all ();
				return opened;

			}


			void Stop () {

				std::lock_guard<std::mutex> lock (stateMutex);
				running = false;

			}


		private:

			// The native format nearest the size asked for, then the nearest rate at or
			// above the one asked for, preferring formats that need no decoding
			static IMFMediaType* ChooseNativeType (IMFSourceReader* reader, int requestedWidth, int requestedHeight, double requestedFrameRate) {

				IMFMediaType* best = NULL;
				double bestScore = 0;

				for (DWORD i = 0; ; i++) {

					IMFMediaType* type = NULL;
					if (FAILED (reader->GetNativeMediaType ((DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM, i, &type))) break;

					UINT32 typeWidth = 0, typeHeight = 0, numerator = 0, denominator = 1;
					GUID subtype = {};
					MFGetAttributeSize (type, MF_MT_FRAME_SIZE, &typeWidth, &typeHeight);
					MFGetAttributeRatio (type, MF_MT_FRAME_RATE, &numerator, &denominator);
					type->GetGUID (MF_MT_SUBTYPE, &subtype);

					double rate = denominator ? (double)numerator / denominator : 0;
					double score = fabs ((double)typeWidth - requestedWidth) + fabs ((double)typeHeight - requestedHeight);
					score = score * 1000 + (rate + 0.5 < requestedFrameRate ? (requestedFrameRate - rate) * 10 : rate - requestedFrameRate);
					if (subtype == MFVideoFormat_MJPG) score += 0.5;

					if (!best || score < bestScore) {

						CameraRelease (&best);
						best = type;
						bestScore = score;

					} else {

						type->Release ();

					}

				}

				return best;

			}


			void Finish (bool success) {

				std::lock_guard<std::mutex> lock (stateMutex);
				opened = success;
				ready = true;
				stateCondition.notify_all ();

			}


			void Run (std::string device, int requestedWidth, int requestedHeight, double requestedFrameRate) {

				HRESULT result = CoInitializeEx (NULL, COINIT_MULTITHREADED);
				bool uninitialize = SUCCEEDED (result);
				bool started = SUCCEEDED (cameraMFStartup (MF_VERSION, MFSTARTUP_LITE));

				IMFActivate** devices = NULL;
				UINT32 count = 0;
				IMFMediaSource* source = NULL;
				IMFAttributes* attributes = NULL;
				IMFSourceReader* reader = NULL;
				IMFMediaType* nativeType = NULL;
				IMFMediaType* outputType = NULL;
				IMFMediaType* currentType = NULL;
				LONG stride = 0;
				bool success = false;

				do {

					if (!started || !EnumerateCameras (&devices, &count) || count == 0) break;

					IMFActivate* chosen = NULL;

					for (UINT32 i = 0; i < count && !chosen; i++) {

						if (device.empty () || GetActivateString (devices[i], MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_SYMBOLIC_LINK) == device) chosen = devices[i];

					}

					if (!chosen || FAILED (chosen->ActivateObject (IID_PPV_ARGS (&source)))) break;

					// Advanced video processing decodes and converts what the camera sends,
					// such as YUY2 or MJPEG, to NV12
					if (FAILED (cameraMFCreateAttributes (&attributes, 2))) break;
					attributes->SetUINT32 (MF_SOURCE_READER_ENABLE_ADVANCED_VIDEO_PROCESSING, TRUE);
					attributes->SetUINT32 (MF_READWRITE_DISABLE_CONVERTERS, FALSE);
					if (FAILED (cameraMFCreateSourceReaderFromMediaSource (source, attributes, &reader))) break;

					nativeType = ChooseNativeType (reader, requestedWidth, requestedHeight, requestedFrameRate);
					if (!nativeType) break;

					// Setting a native type picks the camera's own format
					reader->SetCurrentMediaType ((DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM, NULL, nativeType);

					UINT32 typeWidth = 0, typeHeight = 0;
					MFGetAttributeSize (nativeType, MF_MT_FRAME_SIZE, &typeWidth, &typeHeight);

					if (FAILED (cameraMFCreateMediaType (&outputType))) break;
					outputType->SetGUID (MF_MT_MAJOR_TYPE, MFMediaType_Video);
					outputType->SetGUID (MF_MT_SUBTYPE, MFVideoFormat_NV12);
					MFSetAttributeSize (outputType, MF_MT_FRAME_SIZE, typeWidth, typeHeight);
					if (FAILED (reader->SetCurrentMediaType ((DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM, NULL, outputType))) break;
					if (FAILED (reader->GetCurrentMediaType ((DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM, &currentType))) break;

					UINT32 numerator = 0, denominator = 1;
					MFGetAttributeSize (currentType, MF_MT_FRAME_SIZE, &typeWidth, &typeHeight);
					MFGetAttributeRatio (nativeType, MF_MT_FRAME_RATE, &numerator, &denominator);

					UINT32 defaultStride = 0;
					stride = SUCCEEDED (currentType->GetUINT32 (MF_MT_DEFAULT_STRIDE, &defaultStride)) ? (LONG)defaultStride : (LONG)typeWidth;

					UINT32 matrix = MFVideoTransferMatrix_BT601;
					UINT32 range = MFNominalRange_16_235;
					currentType->GetUINT32 (MF_MT_YUV_MATRIX, &matrix);
					currentType->GetUINT32 (MF_MT_VIDEO_NOMINAL_RANGE, &range);

					width = (int)typeWidth;
					height = (int)typeHeight;
					frameRate = denominator ? (double)numerator / denominator : 0;
					colorMatrix = matrix == MFVideoTransferMatrix_BT709 ? VIDEO_COLOR_MATRIX_BT709 : VIDEO_COLOR_MATRIX_BT601;
					fullRange = range == MFNominalRange_0_255;
					success = width > 0 && height > 0;

				} while (false);

				Finish (success);

				if (success) Capture (reader, stride);

				CameraRelease (&currentType);
				CameraRelease (&outputType);
				CameraRelease (&nativeType);
				CameraRelease (&reader);
				CameraRelease (&attributes);
				if (source) source->Shutdown ();
				CameraRelease (&source);

				for (UINT32 i = 0; i < count; i++) devices[i]->Release ();
				CoTaskMemFree (devices);

				if (started) cameraMFShutdown ();
				if (uninitialize) CoUninitialize ();

			}


			void Capture (IMFSourceReader* reader, LONG stride) {

				bool reading = false;

				while (true) {

					{
						std::unique_lock<std::mutex> lock (stateMutex);
						stateCondition.wait (lock, [this] { return quit || running; });
						if (quit) break;
					}

					// The camera stays on between start and stop only
					if (!reading) reading = true;

					DWORD flags = 0;
					LONGLONG timestamp = 0;
					IMFSample* sample = NULL;
					HRESULT result = reader->ReadSample ((DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0, NULL, &flags, &timestamp, &sample);

					if (FAILED (result) || (flags & (MF_SOURCE_READERF_ERROR | MF_SOURCE_READERF_ENDOFSTREAM))) {

						CameraRelease (&sample);
						SetDisconnected ();
						break;

					}

					if (sample) {

						WriteSample (sample, stride, timestamp / 10000000.0);
						sample->Release ();

					}

					bool stopped;

					{
						std::lock_guard<std::mutex> lock (stateMutex);
						stopped = !running;
					}

					// Flushing lets the camera's queued frames go, so a restart shows a
					// new frame first
					if (stopped && reading) {

						reader->Flush ((DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM);
						reading = false;

					}

				}

			}


			void WriteSample (IMFSample* sample, LONG defaultStride, double time) {

				IMFMediaBuffer* buffer = NULL;
				if (FAILED (sample->GetBufferByIndex (0, &buffer))) return;

				IMF2DBuffer* buffer2D = NULL;
				BYTE* scanline = NULL;
				LONG pitch = 0;
				BYTE* data = NULL;
				DWORD length = 0;
				bool locked2D = SUCCEEDED (buffer->QueryInterface (IID_PPV_ARGS (&buffer2D))) && SUCCEEDED (buffer2D->Lock2D (&scanline, &pitch));

				if (!locked2D) {

					CameraRelease (&buffer2D);

					if (FAILED (buffer->Lock (&data, NULL, &length))) {

						buffer->Release ();
						return;

					}

					scanline = data;
					pitch = defaultStride;

				}

				if (pitch > 0) {

					VideoPlanes planes;
					planes.colorMatrix = colorMatrix;
					planes.fullRange = fullRange;
					planes.height = height;
					planes.transfer = VIDEO_COLOR_TRANSFER_SDR;
					planes.width = width;
					planes.y = scanline;
					planes.yStride = pitch;
					planes.u = scanline + (size_t)pitch * height;
					planes.v = planes.u + 1;
					planes.uvPixelStride = 2;
					planes.uvStride = pitch;

					if (locked2D || length >= (DWORD)(pitch * height * 3 / 2)) PushFrame (&planes, time);

				}

				if (locked2D) {

					buffer2D->Unlock2D ();
					buffer2D->Release ();

				} else {

					buffer->Unlock ();

				}

				buffer->Release ();

			}


			VideoColorMatrix colorMatrix;
			bool fullRange;
			bool opened;
			bool quit;
			bool ready;
			bool running;
			std::condition_variable stateCondition;
			std::mutex stateMutex;
			std::thread thread;


	};


	bool CameraCapture::GetDevices (std::vector<CameraDeviceInfo>* devices) {

		if (!LoadCameraMediaFoundation ()) return false;

		bool listed = false;

		RunInMediaFoundation ([devices, &listed] {

			IMFActivate** activates = NULL;
			UINT32 count = 0;
			if (!EnumerateCameras (&activates, &count)) return;

			for (UINT32 i = 0; i < count; i++) {

				CameraDeviceInfo info;
				info.id = GetActivateString (activates[i], MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_SYMBOLIC_LINK);
				info.name = GetActivateString (activates[i], MF_DEVSOURCE_ATTRIBUTE_FRIENDLY_NAME);
				info.position = CAMERA_POSITION_UNKNOWN;
				devices->push_back (info);
				activates[i]->Release ();

			}

			CoTaskMemFree (activates);
			listed = true;

		});

		return listed;

	}


	// Windows asks nothing of desktop applications, but the user can turn the camera
	// off for them in the privacy settings
	int CameraCapture::GetPermissionStatus () {

		const wchar_t* keys[2] = {
			L"Software\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\webcam",
			L"Software\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\webcam\\NonPackaged"
		};

		for (int i = 0; i < 2; i++) {

			wchar_t value[16];
			DWORD size = sizeof (value);

			if (RegGetValueW (HKEY_CURRENT_USER, keys[i], L"Value", RRF_RT_REG_SZ, NULL, value, &size) == ERROR_SUCCESS && wcscmp (value, L"Deny") == 0) {

				return 2;

			}

		}

		return 1;

	}


	bool CameraCapture::IsSupported () {

		return LoadCameraMediaFoundation ();

	}


	CameraCapture* CameraCapture::Open (const char* id, int width, int height, double frameRate) {

		if (!LoadCameraMediaFoundation ()) return NULL;

		MFCameraCapture* capture = new MFCameraCapture ();

		if (!capture->Open (id, width > 0 ? width : 640, height > 0 ? height : 480, frameRate > 0 ? frameRate : 30)) {

			delete capture;
			return NULL;

		}

		return capture;

	}


	void CameraCapture::RequestPermission () {}


}


#endif
