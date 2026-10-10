#if defined (HX_WINDOWS) && !defined (HX_WINRT)

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif

// Declares the Windows 8 DXGI device manager, which is loaded at runtime
#if !defined (_WIN32_WINNT) || _WIN32_WINNT < 0x0602
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0602
#endif
#if !defined (WINVER) || WINVER < 0x0602
#undef WINVER
#define WINVER 0x0602
#endif

#include <windows.h>
#include <initguid.h>
#include <d3d11.h>
#include <d3d11_1.h>
#include <d3d10.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mferror.h>
#include <mfreadwrite.h>
#include <chrono>
#include <condition_variable>
#include <deque>
#include <map>
#include <mutex>
#include <string>
#include <utility>

#ifndef NATIVE_TOOLKIT_SDL_ANGLE
#include <GL/gl.h>
#define LIME_VIDEO_WGL_INTEROP
#endif

#endif

#include <media/VideoDecoder.h>


#ifdef LIME_VIDEO_MEDIA_FOUNDATION


namespace lime {


	// Media Foundation is missing from Windows N editions, so it is loaded at
	// runtime instead of linked
	typedef HRESULT (WINAPI *MFCreateAttributesFunc) (IMFAttributes**, UINT32);
	typedef HRESULT (WINAPI *MFCreateDXGIDeviceManagerFunc) (UINT*, IMFDXGIDeviceManager**);
	typedef HRESULT (WINAPI *MFCreateMediaTypeFunc) (IMFMediaType**);
	typedef HRESULT (WINAPI *MFCreateSourceReaderFromURLFunc) (LPCWSTR, IMFAttributes*, IMFSourceReader**);
	typedef HRESULT (WINAPI *MFShutdownFunc) ();
	typedef HRESULT (WINAPI *MFStartupFunc) (ULONG, DWORD);

	// GUID_NULL, the 100-nanosecond time format for SetCurrentPosition
	static const GUID TIME_FORMAT_100NS = {};

	// Hardware frames are copied to staging textures and mapped STAGING_DELAY
	// frames later, so reading them back does not wait for the GPU
	static const int STAGING_DELAY = 2;
	static const int STAGING_TEXTURES = 4;

	// Texture output converts frames on the GPU into a ring of RGB textures,
	// enough for the decoder's queue, the frame on screen and one being written
	static const int OUTPUT_TEXTURES = 8;

	#ifdef LIME_VIDEO_WGL_INTEROP
	// WGL_NV_DX_interop2, which shares Direct3D 11 textures with OpenGL
	typedef BOOL (WINAPI *WGLDXCloseDeviceFunc) (HANDLE);
	typedef BOOL (WINAPI *WGLDXLockObjectsFunc) (HANDLE, GLint, HANDLE*);
	typedef HANDLE (WINAPI *WGLDXOpenDeviceFunc) (void*);
	typedef HANDLE (WINAPI *WGLDXRegisterObjectFunc) (HANDLE, void*, GLuint, GLenum, GLenum);
	typedef BOOL (WINAPI *WGLDXUnlockObjectsFunc) (HANDLE, GLint, HANDLE*);
	typedef BOOL (WINAPI *WGLDXUnregisterObjectFunc) (HANDLE, HANDLE);

	static const GLenum WGL_ACCESS_READ_ONLY = 0x0000;

	static WGLDXCloseDeviceFunc _wglDXCloseDeviceNV = 0;
	static WGLDXLockObjectsFunc _wglDXLockObjectsNV = 0;
	static WGLDXOpenDeviceFunc _wglDXOpenDeviceNV = 0;
	static WGLDXRegisterObjectFunc _wglDXRegisterObjectNV = 0;
	static WGLDXUnlockObjectsFunc _wglDXUnlockObjectsNV = 0;
	static WGLDXUnregisterObjectFunc _wglDXUnregisterObjectNV = 0;
	#endif


	struct MFOutputTexture {

		GLuint glTexture;
		HANDLE interop;
		ID3D11Texture2D* texture;
		ID3D11VideoProcessorOutputView* view;

	};


	class MFTextureFrame : public VideoTextureFrame {

		public:

			int index;

	};

	static PFN_D3D11_CREATE_DEVICE _D3D11CreateDevice = 0;
	static MFCreateAttributesFunc _MFCreateAttributes = 0;
	static MFCreateDXGIDeviceManagerFunc _MFCreateDXGIDeviceManager = 0;
	static MFCreateMediaTypeFunc _MFCreateMediaType = 0;
	static MFCreateSourceReaderFromURLFunc _MFCreateSourceReaderFromURL = 0;
	static MFShutdownFunc _MFShutdown = 0;
	static MFStartupFunc _MFStartup = 0;

	static std::once_flag loadFlag;
	static bool loaded = false;


	static bool LoadMediaFoundation () {

		std::call_once (loadFlag, [] {

			HMODULE mfplat = LoadLibraryW (L"mfplat.dll");
			HMODULE mfreadwrite = LoadLibraryW (L"mfreadwrite.dll");

			if (!mfplat || !mfreadwrite) return;

			_MFCreateAttributes = (MFCreateAttributesFunc)GetProcAddress (mfplat, "MFCreateAttributes");
			_MFCreateDXGIDeviceManager = (MFCreateDXGIDeviceManagerFunc)GetProcAddress (mfplat, "MFCreateDXGIDeviceManager");
			_MFCreateMediaType = (MFCreateMediaTypeFunc)GetProcAddress (mfplat, "MFCreateMediaType");
			_MFShutdown = (MFShutdownFunc)GetProcAddress (mfplat, "MFShutdown");
			_MFStartup = (MFStartupFunc)GetProcAddress (mfplat, "MFStartup");
			_MFCreateSourceReaderFromURL = (MFCreateSourceReaderFromURLFunc)GetProcAddress (mfreadwrite, "MFCreateSourceReaderFromURL");

			HMODULE d3d11 = LoadLibraryW (L"d3d11.dll");
			if (d3d11) _D3D11CreateDevice = (PFN_D3D11_CREATE_DEVICE)GetProcAddress (d3d11, "D3D11CreateDevice");

			loaded = (_MFCreateAttributes && _MFCreateMediaType && _MFShutdown && _MFStartup && _MFCreateSourceReaderFromURL);

		});

		return loaded;

	}


	static void InitializeCOM () {

		// Media Foundation objects are free-threaded, so each decoding thread
		// joins the multithreaded apartment. A thread that is already in an
		// apartment keeps it.
		static thread_local bool initialized = false;

		if (!initialized) {

			CoInitializeEx (NULL, COINIT_MULTITHREADED);
			initialized = true;

		}

	}


	static std::wstring GetURL (const char* path) {

		int length = MultiByteToWideChar (CP_UTF8, 0, path, -1, NULL, 0);
		if (length <= 0) return std::wstring ();

		std::wstring wide (length, 0);
		MultiByteToWideChar (CP_UTF8, 0, path, -1, &wide[0], length);
		wide.resize (length - 1);

		if (wide.find (L"://") != std::wstring::npos) return wide;

		DWORD fullLength = GetFullPathNameW (wide.c_str (), 0, NULL, NULL);
		if (fullLength == 0) return wide;

		std::wstring full (fullLength, 0);
		fullLength = GetFullPathNameW (wide.c_str (), fullLength, &full[0], NULL);
		full.resize (fullLength);
		return full;

	}


	class MFVideoBackend : public VideoBackend {


		public:

			MFVideoBackend ();
			~MFVideoBackend ();

			virtual void Close ();
			virtual VideoDecodeResult DecodeAudio (std::vector<unsigned char>* pcm, double* time);
			virtual VideoDecodeResult DecodeVideo (VideoPlanes* planes, double* time, double* duration);
			virtual bool Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info);
			virtual bool Seek (double time);

		private:

			void ClearStaging ();
			bool CopyToStaging (IMFSample* sample, LONGLONG timestamp, LONGLONG sampleDuration);
			bool CreateDeviceManager ();
			bool CreateProcessor (UINT inputWidth, UINT inputHeight);
			void GetPlanes (VideoPlanes* planes, BYTE* data, int pitch, int lumaRows);
			VideoDecodeResult MapStaging (VideoPlanes* planes, double* time, double* duration);
			bool OpenAudio ();
			bool OpenVideo (bool hardware);
			void ReadVideoFormat ();
			void ReleaseDeviceManager ();
			void ReleaseProcessor ();
			bool SwitchToSoftware ();
			void UnlockVideo ();

			virtual VideoDecodeResult DecodeVideoTexture (VideoTextureFrame** frame, double* time, double* duration);
			virtual unsigned int LockTexture (VideoTextureFrame* frame);
			virtual void ReleaseTextureFrame (VideoTextureFrame* frame);
			virtual void ReleaseTextures ();
			virtual bool SupportsTextures ();
			virtual void UnlockTexture (VideoTextureFrame* frame);

			int audioChannels;
			IMFSourceReader* audioReader;
			int audioSampleRate;
			int audioSourceChannels;
			int bufferHeight;
			int bufferWidth;
			VideoColorMatrix colorMatrix;
			int cropHeight;
			int cropWidth;
			int cropX;
			int cropY;
			ID3D11DeviceContext* context;
			LONG defaultStride;
			ID3D11Device* device;
			std::vector<int> freeOutputs;
			MFTextureFrame outputFrames[OUTPUT_TEXTURES];
			std::condition_variable outputCondition;
			std::mutex outputMutex;
			MFOutputTexture outputs[OUTPUT_TEXTURES];
			ID3D11VideoProcessor* processor;
			ID3D11VideoProcessorEnumerator* processorEnumerator;
			UINT processorHeight;
			UINT processorWidth;
			IMFDXGIDeviceManager* deviceManager;
			double frameRate;
			bool fullRange;
			bool hardwareActive;
			std::map<std::pair<ID3D11Texture2D*, UINT>, ID3D11VideoProcessorInputView*> inputViews;
			HANDLE interopDevice;
			bool interopFailed;
			IMF2DBuffer* locked2D;
			IMFMediaBuffer* lockedBuffer;
			ID3D11Texture2D* staging[STAGING_TEXTURES];
			LONGLONG stagingDurations[STAGING_TEXTURES];
			bool stagingFailed;
			bool texturesFailed;
			UINT stagingHeight;
			int stagingMapped;
			bool stagingPrimed;
			std::deque<int> stagingQueue;
			LONGLONG stagingTimes[STAGING_TEXTURES];
			UINT stagingWidth;
			bool started;
			std::wstring url;
			bool videoEnded;
			ID3D11VideoContext* videoContext;
			ID3D11VideoDevice* videoDevice;
			LONGLONG videoPosition;
			IMFSourceReader* videoReader;


	};


	MFVideoBackend::MFVideoBackend () {

		audioChannels = 0;
		audioReader = NULL;
		audioSampleRate = 0;
		audioSourceChannels = 0;
		bufferHeight = 0;
		bufferWidth = 0;
		colorMatrix = VIDEO_COLOR_MATRIX_BT709;
		cropHeight = 0;
		cropWidth = 0;
		cropX = 0;
		cropY = 0;
		context = NULL;
		defaultStride = 0;
		device = NULL;
		deviceManager = NULL;
		frameRate = 0;
		fullRange = false;
		hardwareActive = false;
		interopDevice = NULL;
		interopFailed = false;
		locked2D = NULL;
		lockedBuffer = NULL;
		processor = NULL;
		processorEnumerator = NULL;
		processorHeight = 0;
		processorWidth = 0;
		stagingFailed = false;
		stagingHeight = 0;
		stagingMapped = -1;
		stagingPrimed = false;
		stagingWidth = 0;
		texturesFailed = false;
		videoContext = NULL;
		videoDevice = NULL;
		videoEnded = false;
		videoPosition = 0;
		videoReader = NULL;

		for (int i = 0; i < STAGING_TEXTURES; i++) staging[i] = NULL;

		for (int i = 0; i < OUTPUT_TEXTURES; i++) {

			outputs[i].glTexture = 0;
			outputs[i].interop = NULL;
			outputs[i].texture = NULL;
			outputs[i].view = NULL;
			outputFrames[i].index = i;

		}

		InitializeCOM ();
		started = SUCCEEDED (_MFStartup (MF_VERSION, MFSTARTUP_FULL));

	}


	MFVideoBackend::~MFVideoBackend () {

		Close ();

		if (started) _MFShutdown ();

	}


	void MFVideoBackend::Close () {

		// Closing away from the GL thread leaves the textures it shares with
		// OpenGL behind, rather than using them with the next device
		for (int i = 0; i < OUTPUT_TEXTURES; i++) {

			if (outputs[i].interop) {

				outputs[i].glTexture = 0;
				outputs[i].interop = NULL;
				outputs[i].texture = NULL;

			}

		}

		interopDevice = NULL;
		interopFailed = false;

		UnlockVideo ();

		if (videoReader) {

			videoReader->Release ();
			videoReader = NULL;

		}

		if (audioReader) {

			audioReader->Release ();
			audioReader = NULL;

		}

		ReleaseDeviceManager ();

		audioChannels = 0;
		audioSampleRate = 0;
		audioSourceChannels = 0;
		hardwareActive = false;
		stagingFailed = false;
		stagingPrimed = false;
		texturesFailed = false;
		videoEnded = false;
		videoPosition = 0;

	}


	void MFVideoBackend::ClearStaging () {

		if (stagingMapped >= 0) {

			context->Unmap (staging[stagingMapped], 0);
			stagingMapped = -1;

		}

		stagingQueue.clear ();

	}


	bool MFVideoBackend::CopyToStaging (IMFSample* sample, LONGLONG timestamp, LONGLONG sampleDuration) {

		if (!context || stagingFailed) return false;

		IMFMediaBuffer* buffer = NULL;
		IMFDXGIBuffer* dxgiBuffer = NULL;
		ID3D11Texture2D* texture = NULL;
		UINT subresource = 0;
		bool copied = false;

		if (SUCCEEDED (sample->GetBufferByIndex (0, &buffer)) && SUCCEEDED (buffer->QueryInterface (IID_PPV_ARGS (&dxgiBuffer)))
			&& SUCCEEDED (dxgiBuffer->GetResource (IID_PPV_ARGS (&texture))) && SUCCEEDED (dxgiBuffer->GetSubresourceIndex (&subresource))) {

			D3D11_TEXTURE2D_DESC desc;
			texture->GetDesc (&desc);

			if (desc.Format == DXGI_FORMAT_NV12 && (desc.Width != stagingWidth || desc.Height != stagingHeight)) {

				ClearStaging ();

				for (int i = 0; i < STAGING_TEXTURES; i++) {

					if (staging[i]) staging[i]->Release ();
					staging[i] = NULL;

				}

				D3D11_TEXTURE2D_DESC stagingDesc = {};
				stagingDesc.Width = desc.Width;
				stagingDesc.Height = desc.Height;
				stagingDesc.MipLevels = 1;
				stagingDesc.ArraySize = 1;
				stagingDesc.Format = DXGI_FORMAT_NV12;
				stagingDesc.SampleDesc.Count = 1;
				stagingDesc.Usage = D3D11_USAGE_STAGING;
				stagingDesc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;

				bool created = true;

				for (int i = 0; i < STAGING_TEXTURES && created; i++) {

					created = SUCCEEDED (device->CreateTexture2D (&stagingDesc, NULL, &staging[i]));

				}

				stagingWidth = created ? desc.Width : 0;
				stagingHeight = created ? desc.Height : 0;

			}

			if (desc.Format == DXGI_FORMAT_NV12 && stagingWidth == desc.Width && stagingHeight == desc.Height) {

				// Use a texture that is neither mapped nor waiting to be
				int index = -1;

				for (int i = 0; i < STAGING_TEXTURES && index < 0; i++) {

					bool used = (i == stagingMapped);
					for (size_t j = 0; j < stagingQueue.size () && !used; j++) used = (stagingQueue[j] == i);
					if (!used) index = i;

				}

				if (index >= 0) {

					context->CopySubresourceRegion (staging[index], 0, 0, 0, 0, texture, subresource, NULL);
					stagingDurations[index] = sampleDuration;
					stagingTimes[index] = timestamp;
					stagingQueue.push_back (index);
					copied = true;

				}

			}

		}

		if (texture) texture->Release ();
		if (dxgiBuffer) dxgiBuffer->Release ();
		if (buffer) buffer->Release ();

		// The frames already queued would come out of order, so they are
		// dropped if copying stops working
		if (!copied) {

			stagingFailed = true;
			ClearStaging ();

		}

		return copied;

	}


	bool MFVideoBackend::CreateDeviceManager () {

		if (deviceManager) return true;
		if (!_D3D11CreateDevice || !_MFCreateDXGIDeviceManager) return false;

		static const D3D_FEATURE_LEVEL levels[] = { D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_1, D3D_FEATURE_LEVEL_10_0, D3D_FEATURE_LEVEL_9_3 };

		UINT flags = D3D11_CREATE_DEVICE_VIDEO_SUPPORT | D3D11_CREATE_DEVICE_BGRA_SUPPORT;
		HRESULT hr = _D3D11CreateDevice (NULL, D3D_DRIVER_TYPE_HARDWARE, NULL, flags, levels, ARRAYSIZE (levels), D3D11_SDK_VERSION, &device, NULL, NULL);

		if (hr == E_INVALIDARG) {

			// Windows 7 without the platform update does not know 11.1
			hr = _D3D11CreateDevice (NULL, D3D_DRIVER_TYPE_HARDWARE, NULL, flags, levels + 1, ARRAYSIZE (levels) - 1, D3D11_SDK_VERSION, &device, NULL, NULL);

		}

		if (FAILED (hr) || !device) {

			device = NULL;
			return false;

		}

		device->GetImmediateContext (&context);

		// Media Foundation uses the device from its own threads
		ID3D10Multithread* multithread = NULL;

		if (SUCCEEDED (device->QueryInterface (IID_PPV_ARGS (&multithread)))) {

			multithread->SetMultithreadProtected (TRUE);
			multithread->Release ();

		}

		UINT token = 0;

		if (FAILED (_MFCreateDXGIDeviceManager (&token, &deviceManager)) || FAILED (deviceManager->ResetDevice (device, token))) {

			ReleaseDeviceManager ();
			return false;

		}

		return true;

	}


	VideoDecodeResult MFVideoBackend::DecodeAudio (std::vector<unsigned char>* pcm, double* time) {

		if (!audioReader) return VIDEO_DECODE_END;

		InitializeCOM ();

		while (true) {

			DWORD flags = 0;
			LONGLONG timestamp = 0;
			IMFSample* sample = NULL;

			HRESULT hr = audioReader->ReadSample (MF_SOURCE_READER_FIRST_AUDIO_STREAM, 0, NULL, &flags, &timestamp, &sample);

			if (FAILED (hr) || (flags & MF_SOURCE_READERF_ERROR)) {

				if (sample) sample->Release ();
				return VIDEO_DECODE_ERROR;

			}

			if (flags & MF_SOURCE_READERF_ENDOFSTREAM) {

				if (sample) sample->Release ();
				return VIDEO_DECODE_END;

			}

			if (!sample) continue;

			IMFMediaBuffer* buffer = NULL;
			hr = sample->ConvertToContiguousBuffer (&buffer);
			sample->Release ();

			if (FAILED (hr)) return VIDEO_DECODE_ERROR;

			BYTE* data = NULL;
			DWORD length = 0;

			if (FAILED (buffer->Lock (&data, NULL, &length))) {

				buffer->Release ();
				return VIDEO_DECODE_ERROR;

			}

			*time = timestamp / 10000000.0;

			if (audioSourceChannels == audioChannels) {

				pcm->insert (pcm->end (), data, data + length);

			} else {

				DownmixToStereo ((const short*)data, length / (audioSourceChannels * 2), audioSourceChannels, pcm);

			}

			buffer->Unlock ();
			buffer->Release ();

			return VIDEO_DECODE_OK;

		}

	}


	VideoDecodeResult MFVideoBackend::DecodeVideo (VideoPlanes* planes, double* time, double* duration) {

		UnlockVideo ();

		if (!videoReader) return VIDEO_DECODE_END;

		InitializeCOM ();

		while (true) {

			// The first frame after opening or seeking is mapped straight away, so
			// only frames that follow it wait for the pipeline
			if (!stagingQueue.empty () && (stagingQueue.size () >= (size_t)STAGING_DELAY || videoEnded || !stagingPrimed)) {

				stagingPrimed = true;
				return MapStaging (planes, time, duration);

			}

			if (videoEnded) return VIDEO_DECODE_END;

			DWORD flags = 0;
			LONGLONG timestamp = 0;
			IMFSample* sample = NULL;

			HRESULT hr = videoReader->ReadSample (MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0, NULL, &flags, &timestamp, &sample);

			if (FAILED (hr) || (flags & MF_SOURCE_READERF_ERROR)) {

				if (sample) sample->Release ();

				if (hardwareActive && SwitchToSoftware ()) continue;

				return VIDEO_DECODE_ERROR;

			}

			if (flags & MF_SOURCE_READERF_CURRENTMEDIATYPECHANGED) ReadVideoFormat ();

			if (flags & MF_SOURCE_READERF_ENDOFSTREAM) {

				if (sample) sample->Release ();
				videoEnded = true;
				continue;

			}

			if (!sample) continue;

			LONGLONG sampleDuration = 0;
			sample->GetSampleDuration (&sampleDuration);

			if (hardwareActive && CopyToStaging (sample, timestamp, sampleDuration)) {

				sample->Release ();
				continue;

			}

			IMFMediaBuffer* buffer = NULL;
			DWORD bufferCount = 0;
			sample->GetBufferCount (&bufferCount);

			if (bufferCount == 1) {

				hr = sample->GetBufferByIndex (0, &buffer);

			} else {

				hr = sample->ConvertToContiguousBuffer (&buffer);

			}

			sample->Release ();

			if (FAILED (hr)) return VIDEO_DECODE_ERROR;

			BYTE* data = NULL;
			LONG pitch = 0;
			DWORD length = 0;
			IMF2DBuffer2* buffer2D2 = NULL;
			IMF2DBuffer* buffer2D = NULL;

			if (SUCCEEDED (buffer->QueryInterface (IID_PPV_ARGS (&buffer2D2)))) {

				BYTE* start = NULL;

				if (SUCCEEDED (buffer2D2->Lock2DSize (MF2DBuffer_LockFlags_Read, &data, &pitch, &start, &length))) {

					buffer2D = buffer2D2;

				} else {

					buffer2D2->Release ();

				}

			}

			if (!buffer2D && SUCCEEDED (buffer->QueryInterface (IID_PPV_ARGS (&buffer2D)))) {

				if (FAILED (buffer2D->Lock2D (&data, &pitch))) {

					buffer2D->Release ();
					buffer2D = NULL;

				}

			}

			if (!buffer2D) {

				if (FAILED (buffer->Lock (&data, NULL, &length))) {

					buffer->Release ();
					return VIDEO_DECODE_ERROR;

				}

				pitch = defaultStride > 0 ? defaultStride : bufferWidth;

			}

			lockedBuffer = buffer;
			locked2D = buffer2D;

			if (pitch <= 0 || !data) {

				UnlockVideo ();
				return VIDEO_DECODE_ERROR;

			}

			// The luma plane is normally the frame size from the media type, but
			// some decoders align the surface further
			int lumaRows = bufferHeight;

			if (length > 0) {

				int rows = (int)(length / pitch);
				int alignedRows = (rows * 2) / 3;
				if (alignedRows > lumaRows && alignedRows <= lumaRows + 64) lumaRows = alignedRows;

				if ((DWORD)pitch * (lumaRows + (lumaRows + 1) / 2) > length) {

					UnlockVideo ();
					return VIDEO_DECODE_ERROR;

				}

			}

			GetPlanes (planes, data, pitch, lumaRows);

			videoPosition = timestamp;
			*time = timestamp / 10000000.0;
			*duration = sampleDuration > 0 ? sampleDuration / 10000000.0 : (frameRate > 0 ? 1.0 / frameRate : 0);

			return VIDEO_DECODE_OK;

		}

	}


	void MFVideoBackend::GetPlanes (VideoPlanes* planes, BYTE* data, int pitch, int lumaRows) {

		planes->colorMatrix = colorMatrix;
		planes->fullRange = fullRange;
		planes->width = cropWidth;
		planes->height = cropHeight;
		planes->y = data + cropY * pitch + cropX;
		planes->yStride = pitch;
		planes->u = data + lumaRows * pitch + (cropY / 2) * pitch + (cropX & ~1);
		planes->v = planes->u + 1;
		planes->uvStride = pitch;
		planes->uvPixelStride = 2;

	}


	VideoDecodeResult MFVideoBackend::MapStaging (VideoPlanes* planes, double* time, double* duration) {

		int index = stagingQueue.front ();
		stagingQueue.pop_front ();

		D3D11_MAPPED_SUBRESOURCE mapped;
		if (FAILED (context->Map (staging[index], 0, D3D11_MAP_READ, 0, &mapped))) return VIDEO_DECODE_ERROR;

		stagingMapped = index;

		// The chroma plane of a mapped NV12 texture follows its luma rows
		GetPlanes (planes, (BYTE*)mapped.pData, (int)mapped.RowPitch, (int)stagingHeight);

		videoPosition = stagingTimes[index];
		*time = stagingTimes[index] / 10000000.0;
		*duration = stagingDurations[index] > 0 ? stagingDurations[index] / 10000000.0 : (frameRate > 0 ? 1.0 / frameRate : 0);

		return VIDEO_DECODE_OK;

	}


	bool MFVideoBackend::Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info) {

		Close ();

		if (!started || !path || !path[0]) return false;

		InitializeCOM ();

		url = GetURL (path);
		if (url.empty ()) return false;

		info->hasVideo = OpenVideo (hardwareDecoding) || (hardwareDecoding && OpenVideo (false));
		info->hasAudio = OpenAudio ();

		if (!info->hasVideo && !info->hasAudio) return false;

		IMFSourceReader* reader = videoReader ? videoReader : audioReader;
		PROPVARIANT duration;
		PropVariantInit (&duration);

		if (SUCCEEDED (reader->GetPresentationAttribute (MF_SOURCE_READER_MEDIASOURCE, MF_PD_DURATION, &duration)) && duration.vt == VT_UI8) {

			info->duration = duration.uhVal.QuadPart / 10000000.0;

		}

		PropVariantClear (&duration);

		info->audioChannels = audioChannels;
		info->audioSampleRate = audioSampleRate;
		info->frameRate = frameRate;
		info->width = info->hasVideo ? cropWidth : 0;
		info->height = info->hasVideo ? cropHeight : 0;

		return true;

	}


	bool MFVideoBackend::OpenAudio () {

		IMFSourceReader* reader = NULL;

		if (FAILED (_MFCreateSourceReaderFromURL (url.c_str (), NULL, &reader))) return false;

		reader->SetStreamSelection (MF_SOURCE_READER_ALL_STREAMS, FALSE);

		IMFMediaType* nativeType = NULL;

		if (FAILED (reader->SetStreamSelection (MF_SOURCE_READER_FIRST_AUDIO_STREAM, TRUE)) || FAILED (reader->GetNativeMediaType (MF_SOURCE_READER_FIRST_AUDIO_STREAM, 0, &nativeType))) {

			reader->Release ();
			return false;

		}

		UINT32 sourceChannels = MFGetAttributeUINT32 (nativeType, MF_MT_AUDIO_NUM_CHANNELS, 0);
		nativeType->Release ();

		IMFMediaType* type = NULL;
		bool configured = false;

		// Ask the decoder to downmix first, and downmix here if it cannot
		for (int attempt = 0; attempt < 2 && !configured; attempt++) {

			bool downmix = (attempt == 0 && sourceChannels > 2);
			if (attempt == 1 && sourceChannels <= 2) break;
			if (FAILED (_MFCreateMediaType (&type))) break;

			type->SetGUID (MF_MT_MAJOR_TYPE, MFMediaType_Audio);
			type->SetGUID (MF_MT_SUBTYPE, MFAudioFormat_PCM);
			type->SetUINT32 (MF_MT_AUDIO_BITS_PER_SAMPLE, 16);
			if (downmix) type->SetUINT32 (MF_MT_AUDIO_NUM_CHANNELS, 2);

			configured = SUCCEEDED (reader->SetCurrentMediaType (MF_SOURCE_READER_FIRST_AUDIO_STREAM, NULL, type));
			type->Release ();
			type = NULL;

		}

		IMFMediaType* currentType = NULL;

		if (!configured || FAILED (reader->GetCurrentMediaType (MF_SOURCE_READER_FIRST_AUDIO_STREAM, &currentType))) {

			reader->Release ();
			return false;

		}

		UINT32 bits = MFGetAttributeUINT32 (currentType, MF_MT_AUDIO_BITS_PER_SAMPLE, 0);
		UINT32 channels = MFGetAttributeUINT32 (currentType, MF_MT_AUDIO_NUM_CHANNELS, 0);
		UINT32 sampleRate = MFGetAttributeUINT32 (currentType, MF_MT_AUDIO_SAMPLES_PER_SECOND, 0);
		currentType->Release ();

		if (bits != 16 || channels == 0 || channels > 8 || sampleRate == 0) {

			reader->Release ();
			return false;

		}

		audioReader = reader;
		audioSampleRate = (int)sampleRate;
		audioSourceChannels = (int)channels;
		audioChannels = channels > 2 ? 2 : (int)channels;

		return true;

	}


	bool MFVideoBackend::OpenVideo (bool hardware) {

		IMFAttributes* attributes = NULL;
		if (FAILED (_MFCreateAttributes (&attributes, 4))) return false;

		if (hardware && CreateDeviceManager ()) {

			attributes->SetUnknown (MF_SOURCE_READER_D3D_MANAGER, deviceManager);
			attributes->SetUINT32 (MF_SOURCE_READER_ENABLE_ADVANCED_VIDEO_PROCESSING, TRUE);
			attributes->SetUINT32 (MF_READWRITE_ENABLE_HARDWARE_TRANSFORMS, TRUE);

		} else {

			hardware = false;
			attributes->SetUINT32 (MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING, TRUE);

		}

		IMFSourceReader* reader = NULL;
		HRESULT hr = _MFCreateSourceReaderFromURL (url.c_str (), attributes, &reader);
		attributes->Release ();

		if (FAILED (hr)) {

			if (hardware) ReleaseDeviceManager ();
			return false;

		}

		reader->SetStreamSelection (MF_SOURCE_READER_ALL_STREAMS, FALSE);

		IMFMediaType* type = NULL;
		bool configured = SUCCEEDED (reader->SetStreamSelection (MF_SOURCE_READER_FIRST_VIDEO_STREAM, TRUE)) && SUCCEEDED (_MFCreateMediaType (&type));

		if (configured) {

			type->SetGUID (MF_MT_MAJOR_TYPE, MFMediaType_Video);
			type->SetGUID (MF_MT_SUBTYPE, MFVideoFormat_NV12);
			configured = SUCCEEDED (reader->SetCurrentMediaType (MF_SOURCE_READER_FIRST_VIDEO_STREAM, NULL, type));
			type->Release ();

		}

		if (!configured) {

			reader->Release ();
			if (hardware) ReleaseDeviceManager ();
			return false;

		}

		videoReader = reader;
		hardwareActive = hardware;
		ReadVideoFormat ();

		if (cropWidth <= 0 || cropHeight <= 0) {

			videoReader->Release ();
			videoReader = NULL;
			if (hardware) ReleaseDeviceManager ();
			return false;

		}

		return true;

	}


	void MFVideoBackend::ReadVideoFormat () {

		IMFMediaType* type = NULL;
		if (FAILED (videoReader->GetCurrentMediaType (MF_SOURCE_READER_FIRST_VIDEO_STREAM, &type))) return;

		UINT32 width = 0;
		UINT32 height = 0;
		MFGetAttributeSize (type, MF_MT_FRAME_SIZE, &width, &height);

		bufferWidth = (int)width;
		bufferHeight = (int)height;
		cropX = 0;
		cropY = 0;
		cropWidth = (int)width;
		cropHeight = (int)height;

		MFVideoArea area;

		if (SUCCEEDED (type->GetBlob (MF_MT_MINIMUM_DISPLAY_APERTURE, (UINT8*)&area, sizeof (area), NULL))) {

			int x = area.OffsetX.value;
			int y = area.OffsetY.value;

			if (x >= 0 && y >= 0 && area.Area.cx > 0 && area.Area.cy > 0 && x + area.Area.cx <= (int)width && y + area.Area.cy <= (int)height) {

				cropX = x;
				cropY = y;
				cropWidth = area.Area.cx;
				cropHeight = area.Area.cy;

			}

		}

		UINT32 stride = 0;
		defaultStride = SUCCEEDED (type->GetUINT32 (MF_MT_DEFAULT_STRIDE, &stride)) ? (LONG)stride : (LONG)width;

		UINT32 numerator = 0;
		UINT32 denominator = 0;

		if (SUCCEEDED (MFGetAttributeRatio (type, MF_MT_FRAME_RATE, &numerator, &denominator)) && denominator > 0) {

			frameRate = (double)numerator / denominator;

		}

		// Video processing can drop the color attributes, so fall back to the
		// stream's own media type
		IMFMediaType* nativeType = NULL;
		videoReader->GetNativeMediaType (MF_SOURCE_READER_FIRST_VIDEO_STREAM, MF_SOURCE_READER_CURRENT_TYPE_INDEX, &nativeType);

		UINT32 matrix = MFGetAttributeUINT32 (type, MF_MT_YUV_MATRIX, MFVideoTransferMatrix_Unknown);
		if (matrix == MFVideoTransferMatrix_Unknown && nativeType) matrix = MFGetAttributeUINT32 (nativeType, MF_MT_YUV_MATRIX, MFVideoTransferMatrix_Unknown);

		UINT32 range = MFGetAttributeUINT32 (type, MF_MT_VIDEO_NOMINAL_RANGE, MFNominalRange_Unknown);
		if (range == MFNominalRange_Unknown && nativeType) range = MFGetAttributeUINT32 (nativeType, MF_MT_VIDEO_NOMINAL_RANGE, MFNominalRange_Unknown);

		if (nativeType) nativeType->Release ();
		type->Release ();

		switch (matrix) {

			case MFVideoTransferMatrix_BT601: colorMatrix = VIDEO_COLOR_MATRIX_BT601; break;
			case MFVideoTransferMatrix_BT709: colorMatrix = VIDEO_COLOR_MATRIX_BT709; break;
			case 4: case 5: colorMatrix = VIDEO_COLOR_MATRIX_BT2020; break;
			default: colorMatrix = GetDefaultColorMatrix (cropWidth, cropHeight); break;

		}

		fullRange = (range == MFNominalRange_0_255);

	}


	void MFVideoBackend::ReleaseDeviceManager () {

		ReleaseProcessor ();

		for (int i = 0; i < OUTPUT_TEXTURES; i++) {

			// Textures still shared with OpenGL are left for ReleaseTextures
			if (outputs[i].interop) continue;
			if (outputs[i].texture) outputs[i].texture->Release ();
			outputs[i].texture = NULL;

		}

		if (videoContext) {

			videoContext->Release ();
			videoContext = NULL;

		}

		if (videoDevice) {

			videoDevice->Release ();
			videoDevice = NULL;

		}

		if (context) ClearStaging ();

		for (int i = 0; i < STAGING_TEXTURES; i++) {

			if (staging[i]) staging[i]->Release ();
			staging[i] = NULL;

		}

		stagingHeight = 0;
		stagingWidth = 0;

		if (context) {

			context->Release ();
			context = NULL;

		}

		if (deviceManager) {

			deviceManager->Release ();
			deviceManager = NULL;

		}

		if (device) {

			device->Release ();
			device = NULL;

		}

	}


	bool MFVideoBackend::Seek (double time) {

		UnlockVideo ();
		stagingPrimed = false;
		stagingQueue.clear ();
		videoEnded = false;

		PROPVARIANT position;
		PropVariantInit (&position);
		position.vt = VT_I8;
		position.hVal.QuadPart = (LONGLONG)(time * 10000000.0);

		bool success = true;

		if (videoReader) {

			success = SUCCEEDED (videoReader->SetCurrentPosition (TIME_FORMAT_100NS, position)) && success;
			videoPosition = position.hVal.QuadPart;

		}

		if (audioReader) success = SUCCEEDED (audioReader->SetCurrentPosition (TIME_FORMAT_100NS, position)) && success;

		return success;

	}


	bool MFVideoBackend::CreateProcessor (UINT inputWidth, UINT inputHeight) {

		ReleaseProcessor ();

		if (!videoDevice && (FAILED (device->QueryInterface (IID_PPV_ARGS (&videoDevice))) || FAILED (context->QueryInterface (IID_PPV_ARGS (&videoContext))))) return false;

		// The output keeps the size the video opened with, so the textures stay
		// shared with OpenGL if the stream changes size
		if (!outputs[0].texture) {

			D3D11_TEXTURE2D_DESC desc = {};
			desc.Width = cropWidth;
			desc.Height = cropHeight;
			desc.MipLevels = 1;
			desc.ArraySize = 1;
			desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
			desc.SampleDesc.Count = 1;
			desc.Usage = D3D11_USAGE_DEFAULT;
			desc.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;

			for (int i = 0; i < OUTPUT_TEXTURES; i++) {

				if (FAILED (device->CreateTexture2D (&desc, NULL, &outputs[i].texture))) return false;

			}

			std::lock_guard<std::mutex> lock (outputMutex);
			freeOutputs.clear ();
			for (int i = 0; i < OUTPUT_TEXTURES; i++) freeOutputs.push_back (i);

		}

		D3D11_TEXTURE2D_DESC outputDesc;
		outputs[0].texture->GetDesc (&outputDesc);

		D3D11_VIDEO_PROCESSOR_CONTENT_DESC contentDesc = {};
		contentDesc.InputFrameFormat = D3D11_VIDEO_FRAME_FORMAT_PROGRESSIVE;
		contentDesc.InputWidth = inputWidth;
		contentDesc.InputHeight = inputHeight;
		contentDesc.OutputWidth = outputDesc.Width;
		contentDesc.OutputHeight = outputDesc.Height;
		contentDesc.Usage = D3D11_VIDEO_USAGE_PLAYBACK_NORMAL;

		UINT support = 0;

		if (FAILED (videoDevice->CreateVideoProcessorEnumerator (&contentDesc, &processorEnumerator))
			|| FAILED (processorEnumerator->CheckVideoProcessorFormat (DXGI_FORMAT_B8G8R8A8_UNORM, &support))
			|| !(support & D3D11_VIDEO_PROCESSOR_FORMAT_SUPPORT_OUTPUT)
			|| FAILED (videoDevice->CreateVideoProcessor (processorEnumerator, 0, &processor))) {

			ReleaseProcessor ();
			return false;

		}

		D3D11_VIDEO_PROCESSOR_OUTPUT_VIEW_DESC viewDesc = {};
		viewDesc.ViewDimension = D3D11_VPOV_DIMENSION_TEXTURE2D;

		for (int i = 0; i < OUTPUT_TEXTURES; i++) {

			if (FAILED (videoDevice->CreateVideoProcessorOutputView (outputs[i].texture, processorEnumerator, &viewDesc, &outputs[i].view))) {

				ReleaseProcessor ();
				return false;

			}

		}

		RECT source = { cropX, cropY, cropX + cropWidth, cropY + cropHeight };
		RECT target = { 0, 0, (LONG)outputDesc.Width, (LONG)outputDesc.Height };

		videoContext->VideoProcessorSetStreamFrameFormat (processor, 0, D3D11_VIDEO_FRAME_FORMAT_PROGRESSIVE);
		videoContext->VideoProcessorSetStreamAutoProcessingMode (processor, 0, FALSE);
		videoContext->VideoProcessorSetStreamSourceRect (processor, 0, TRUE, &source);
		videoContext->VideoProcessorSetStreamDestRect (processor, 0, TRUE, &target);
		videoContext->VideoProcessorSetOutputTargetRect (processor, TRUE, &target);

		ID3D11VideoContext1* videoContext1 = NULL;

		if (colorMatrix == VIDEO_COLOR_MATRIX_BT2020 && SUCCEEDED (videoContext->QueryInterface (IID_PPV_ARGS (&videoContext1)))) {

			// BT.2020 needs the DXGI color spaces from Windows 10
			videoContext1->VideoProcessorSetStreamColorSpace1 (processor, 0, fullRange ? DXGI_COLOR_SPACE_YCBCR_FULL_G22_LEFT_P2020 : DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_LEFT_P2020);
			videoContext1->VideoProcessorSetOutputColorSpace1 (processor, DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709);
			videoContext1->Release ();

		} else {

			D3D11_VIDEO_PROCESSOR_COLOR_SPACE inputSpace = {};
			inputSpace.YCbCr_Matrix = (colorMatrix == VIDEO_COLOR_MATRIX_BT601) ? 0 : 1;
			inputSpace.Nominal_Range = fullRange ? D3D11_VIDEO_PROCESSOR_NOMINAL_RANGE_0_255 : D3D11_VIDEO_PROCESSOR_NOMINAL_RANGE_16_235;
			videoContext->VideoProcessorSetStreamColorSpace (processor, 0, &inputSpace);

			D3D11_VIDEO_PROCESSOR_COLOR_SPACE outputSpace = {};
			outputSpace.RGB_Range = 0;
			videoContext->VideoProcessorSetOutputColorSpace (processor, &outputSpace);

		}

		processorWidth = inputWidth;
		processorHeight = inputHeight;
		return true;

	}


	VideoDecodeResult MFVideoBackend::DecodeVideoTexture (VideoTextureFrame** frame, double* time, double* duration) {

		*frame = NULL;
		UnlockVideo ();

		if (!videoReader) return VIDEO_DECODE_END;

		InitializeCOM ();

		while (true) {

			DWORD flags = 0;
			LONGLONG timestamp = 0;
			IMFSample* sample = NULL;

			HRESULT hr = videoReader->ReadSample (MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0, NULL, &flags, &timestamp, &sample);

			if (FAILED (hr) || (flags & MF_SOURCE_READERF_ERROR)) {

				if (sample) sample->Release ();

				// Continuing in software means decoding into memory from here on
				if (hardwareActive && SwitchToSoftware ()) return VIDEO_DECODE_OK;

				return VIDEO_DECODE_ERROR;

			}

			if (flags & MF_SOURCE_READERF_CURRENTMEDIATYPECHANGED) ReadVideoFormat ();

			if (flags & MF_SOURCE_READERF_ENDOFSTREAM) {

				if (sample) sample->Release ();
				return VIDEO_DECODE_END;

			}

			if (!sample) continue;

			LONGLONG sampleDuration = 0;
			sample->GetSampleDuration (&sampleDuration);

			IMFMediaBuffer* buffer = NULL;
			IMFDXGIBuffer* dxgiBuffer = NULL;
			ID3D11Texture2D* texture = NULL;
			UINT subresource = 0;
			int index = -1;

			if (SUCCEEDED (sample->GetBufferByIndex (0, &buffer)) && SUCCEEDED (buffer->QueryInterface (IID_PPV_ARGS (&dxgiBuffer)))
				&& SUCCEEDED (dxgiBuffer->GetResource (IID_PPV_ARGS (&texture))) && SUCCEEDED (dxgiBuffer->GetSubresourceIndex (&subresource))) {

				D3D11_TEXTURE2D_DESC desc;
				texture->GetDesc (&desc);

				if (processor || CreateProcessor (desc.Width, desc.Height)) {

					if (desc.Width != processorWidth || desc.Height != processorHeight) CreateProcessor (desc.Width, desc.Height);

				}

				std::pair<ID3D11Texture2D*, UINT> key (texture, subresource);
				ID3D11VideoProcessorInputView* inputView = NULL;

				if (processor) {

					std::map<std::pair<ID3D11Texture2D*, UINT>, ID3D11VideoProcessorInputView*>::iterator found = inputViews.find (key);

					if (found != inputViews.end ()) {

						inputView = found->second;

					} else {

						D3D11_VIDEO_PROCESSOR_INPUT_VIEW_DESC inputDesc = {};
						inputDesc.ViewDimension = D3D11_VPIV_DIMENSION_TEXTURE2D;
						inputDesc.Texture2D.ArraySlice = subresource;

						if (SUCCEEDED (videoDevice->CreateVideoProcessorInputView (texture, processorEnumerator, &inputDesc, &inputView))) {

							inputViews[key] = inputView;

						}

					}

				}

				if (inputView) {

					// Wait for the reader to give back a texture
					std::unique_lock<std::mutex> lock (outputMutex);
					outputCondition.wait_for (lock, std::chrono::seconds (5), [this] { return !freeOutputs.empty (); });

					if (!freeOutputs.empty ()) {

						index = freeOutputs.back ();
						freeOutputs.pop_back ();

					}

				}

				if (index >= 0) {

					D3D11_VIDEO_PROCESSOR_STREAM stream = {};
					stream.Enable = TRUE;
					stream.pInputSurface = inputView;

					if (FAILED (videoContext->VideoProcessorBlt (processor, outputs[index].view, 0, 1, &stream))) {

						ReleaseTextureFrame (&outputFrames[index]);
						index = -1;

					} else {

						context->Flush ();

					}

				}

			}

			if (texture) texture->Release ();
			if (dxgiBuffer) dxgiBuffer->Release ();
			if (buffer) buffer->Release ();
			sample->Release ();

			if (index < 0) {

				// Frames that cannot be converted here are decoded into memory
				texturesFailed = true;
				return VIDEO_DECODE_OK;

			}

			outputFrames[index].width = cropWidth;
			outputFrames[index].height = cropHeight;
			*frame = &outputFrames[index];

			videoPosition = timestamp;
			*time = timestamp / 10000000.0;
			*duration = sampleDuration > 0 ? sampleDuration / 10000000.0 : (frameRate > 0 ? 1.0 / frameRate : 0);

			return VIDEO_DECODE_OK;

		}

	}


	unsigned int MFVideoBackend::LockTexture (VideoTextureFrame* frame) {

		#ifdef LIME_VIDEO_WGL_INTEROP
		MFOutputTexture& output = outputs[((MFTextureFrame*)frame)->index];

		if (!interopDevice) {

			if (interopFailed || !wglGetCurrentContext ()) return 0;

			_wglDXOpenDeviceNV = (WGLDXOpenDeviceFunc)wglGetProcAddress ("wglDXOpenDeviceNV");
			_wglDXCloseDeviceNV = (WGLDXCloseDeviceFunc)wglGetProcAddress ("wglDXCloseDeviceNV");
			_wglDXRegisterObjectNV = (WGLDXRegisterObjectFunc)wglGetProcAddress ("wglDXRegisterObjectNV");
			_wglDXUnregisterObjectNV = (WGLDXUnregisterObjectFunc)wglGetProcAddress ("wglDXUnregisterObjectNV");
			_wglDXLockObjectsNV = (WGLDXLockObjectsFunc)wglGetProcAddress ("wglDXLockObjectsNV");
			_wglDXUnlockObjectsNV = (WGLDXUnlockObjectsFunc)wglGetProcAddress ("wglDXUnlockObjectsNV");

			if (_wglDXOpenDeviceNV && _wglDXCloseDeviceNV && _wglDXRegisterObjectNV && _wglDXUnregisterObjectNV && _wglDXLockObjectsNV && _wglDXUnlockObjectsNV) {

				interopDevice = _wglDXOpenDeviceNV (device);

			}

			if (!interopDevice) {

				interopFailed = true;
				return 0;

			}

		}

		if (!output.interop) {

			glGenTextures (1, &output.glTexture);
			output.interop = _wglDXRegisterObjectNV (interopDevice, output.texture, output.glTexture, GL_TEXTURE_2D, WGL_ACCESS_READ_ONLY);

			if (!output.interop) {

				glDeleteTextures (1, &output.glTexture);
				output.glTexture = 0;
				interopFailed = true;
				return 0;

			}

			if (!_wglDXLockObjectsNV (interopDevice, 1, &output.interop)) return 0;

			// Without mipmaps, the default minification filter would leave the
			// texture incomplete
			GLint previousTexture = 0;
			glGetIntegerv (GL_TEXTURE_BINDING_2D, &previousTexture);
			glBindTexture (GL_TEXTURE_2D, output.glTexture);
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, 0x812F);
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, 0x812F);
			glBindTexture (GL_TEXTURE_2D, previousTexture);

			return output.glTexture;

		}

		return _wglDXLockObjectsNV (interopDevice, 1, &output.interop) ? output.glTexture : 0;
		#else
		return 0;
		#endif

	}


	void MFVideoBackend::ReleaseProcessor () {

		for (std::map<std::pair<ID3D11Texture2D*, UINT>, ID3D11VideoProcessorInputView*>::iterator it = inputViews.begin (); it != inputViews.end (); ++it) {

			it->second->Release ();

		}

		inputViews.clear ();

		for (int i = 0; i < OUTPUT_TEXTURES; i++) {

			if (outputs[i].view) outputs[i].view->Release ();
			outputs[i].view = NULL;

		}

		if (processor) {

			processor->Release ();
			processor = NULL;

		}

		if (processorEnumerator) {

			processorEnumerator->Release ();
			processorEnumerator = NULL;

		}

		processorHeight = 0;
		processorWidth = 0;

	}


	void MFVideoBackend::ReleaseTextureFrame (VideoTextureFrame* frame) {

		{
			std::lock_guard<std::mutex> lock (outputMutex);
			freeOutputs.push_back (((MFTextureFrame*)frame)->index);
		}

		outputCondition.notify_one ();

	}


	void MFVideoBackend::ReleaseTextures () {

		#ifdef LIME_VIDEO_WGL_INTEROP
		for (int i = 0; i < OUTPUT_TEXTURES; i++) {

			if (outputs[i].interop) {

				_wglDXUnregisterObjectNV (interopDevice, outputs[i].interop);
				outputs[i].interop = NULL;

			}

			if (outputs[i].glTexture) {

				glDeleteTextures (1, &outputs[i].glTexture);
				outputs[i].glTexture = 0;

			}

		}

		if (interopDevice) {

			_wglDXCloseDeviceNV (interopDevice);
			interopDevice = NULL;

		}
		#endif

		interopFailed = false;

	}


	bool MFVideoBackend::SupportsTextures () {

		return hardwareActive && device && !texturesFailed;

	}


	bool MFVideoBackend::SwitchToSoftware () {

		// Some drivers fail to decode a stream they accepted, so continue from
		// the same position in software
		ClearStaging ();
		videoReader->Release ();
		videoReader = NULL;
		ReleaseDeviceManager ();

		if (!OpenVideo (false)) return false;

		PROPVARIANT position;
		PropVariantInit (&position);
		position.vt = VT_I8;
		position.hVal.QuadPart = videoPosition;
		videoReader->SetCurrentPosition (TIME_FORMAT_100NS, position);
		return true;

	}


	void MFVideoBackend::UnlockTexture (VideoTextureFrame* frame) {

		#ifdef LIME_VIDEO_WGL_INTEROP
		MFOutputTexture& output = outputs[((MFTextureFrame*)frame)->index];
		if (interopDevice && output.interop) _wglDXUnlockObjectsNV (interopDevice, 1, &output.interop);
		#endif

	}


	void MFVideoBackend::UnlockVideo () {

		if (stagingMapped >= 0) {

			context->Unmap (staging[stagingMapped], 0);
			stagingMapped = -1;

		}

		if (locked2D) {

			locked2D->Unlock2D ();
			locked2D->Release ();
			locked2D = NULL;

		} else if (lockedBuffer) {

			lockedBuffer->Unlock ();

		}

		if (lockedBuffer) {

			lockedBuffer->Release ();
			lockedBuffer = NULL;

		}

	}


	VideoBackend* VideoBackend::Create () {

		return LoadMediaFoundation () ? new MFVideoBackend () : NULL;

	}


	bool VideoBackend::IsSupported () {

		return LoadMediaFoundation ();

	}


}


#endif
