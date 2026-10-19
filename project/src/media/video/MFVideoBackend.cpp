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
#include <stdlib.h>
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
	typedef HRESULT (WINAPI *MFCreateSourceReaderFromByteStreamFunc) (IMFByteStream*, IMFAttributes*, IMFSourceReader**);
	typedef HRESULT (WINAPI *MFCreateSourceReaderFromURLFunc) (LPCWSTR, IMFAttributes*, IMFSourceReader**);
	typedef HRESULT (WINAPI *MFCreateSourceResolverFunc) (IMFSourceResolver**);
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

	// How long a seek waits for reads in progress before giving up on them, as
	// reads from a source that is still sending finish well within it
	static const int SEEK_WAIT_MS = 250;

	// MFVideoTransFunc_2084 and _HLG, MFVideoPrimaries_BT2020 and
	// MFVideoTransferMatrix_BT2020_10, which older SDKs lack
	static const UINT32 TRANSFER_PQ = 15;
	static const UINT32 TRANSFER_HLG = 16;
	static const UINT32 PRIMARIES_BT2020 = 9;
	static const UINT32 MATRIX_BT2020 = 4;


	// Reads bits from an H.264 parameter set, skipping emulation prevention
	class MFBitReader {


		public:

			MFBitReader (const UINT8* data, size_t size) : bit (0), data (data), size (size), zeros (0) {}

			bool Bit () {

				if (bit == 0) {

					// A 3 after two zeros only keeps a start code from appearing
					if (zeros >= 2 && size > 0 && *data == 3) {

						data++;
						size--;
						zeros = 0;

					}

					if (size == 0) return false;

				}

				bool value = ((*data >> (7 - bit)) & 1) != 0;

				if (++bit == 8) {

					zeros = *data == 0 ? zeros + 1 : 0;
					bit = 0;
					data++;
					size--;

				}

				return value;

			}

			UINT32 Bits (int count) {

				UINT32 value = 0;
				for (int i = 0; i < count; i++) value = (value << 1) | (Bit () ? 1 : 0);
				return value;

			}

			UINT32 Exp () {

				int count = 0;
				while (!Bit () && count < 32) count++;
				return (UINT32)((1ULL << count) - 1) + Bits (count);

			}

			int SignedExp () {

				UINT32 value = Exp ();
				return (value & 1) ? (int)((value + 1) / 2) : -(int)(value / 2);

			}


		private:

			int bit;
			const UINT8* data;
			size_t size;
			int zeros;


	};


	static VideoColorTransfer ReadH264Transfer (const UINT8* sps, size_t size) {

		// The transfer characteristics in the SPS's video usability information
		MFBitReader reader (sps, size);
		reader.Bits (8);
		UINT32 profile = reader.Bits (8);
		reader.Bits (16);
		reader.Exp ();

		if (profile == 100 || profile == 110 || profile == 122 || profile == 244 || profile == 44 || profile == 83 || profile == 86 || profile == 118 || profile == 128 || profile == 138 || profile == 139 || profile == 134 || profile == 135) {

			UINT32 chroma = reader.Exp ();
			if (chroma == 3) reader.Bit ();
			reader.Exp ();
			reader.Exp ();
			reader.Bit ();

			if (reader.Bit ()) {

				for (int i = 0; i < (chroma != 3 ? 8 : 12); i++) {

					if (!reader.Bit ()) continue;

					int last = 8;
					int next = 8;

					for (int j = 0; j < (i < 6 ? 16 : 64) && next != 0; j++) {

						next = (last + reader.SignedExp () + 256) % 256;
						if (next != 0) last = next;

					}

				}

			}

		}

		reader.Exp ();
		UINT32 order = reader.Exp ();

		if (order == 0) {

			reader.Exp ();

		} else if (order == 1) {

			reader.Bit ();
			reader.SignedExp ();
			reader.SignedExp ();
			UINT32 cycle = reader.Exp ();
			for (UINT32 i = 0; i < cycle && i < 256; i++) reader.SignedExp ();

		}

		reader.Exp ();
		reader.Bit ();
		reader.Exp ();
		reader.Exp ();
		if (!reader.Bit ()) reader.Bit ();
		reader.Bit ();

		if (reader.Bit ()) {

			reader.Exp ();
			reader.Exp ();
			reader.Exp ();
			reader.Exp ();

		}

		if (!reader.Bit ()) return VIDEO_COLOR_TRANSFER_SDR;

		if (reader.Bit () && reader.Bits (8) == 255) reader.Bits (32);
		if (reader.Bit ()) reader.Bit ();
		if (!reader.Bit ()) return VIDEO_COLOR_TRANSFER_SDR;

		reader.Bits (4);
		if (!reader.Bit ()) return VIDEO_COLOR_TRANSFER_SDR;

		reader.Bits (8);
		UINT32 transfer = reader.Bits (8);
		return transfer == 16 ? VIDEO_COLOR_TRANSFER_PQ : (transfer == 18 ? VIDEO_COLOR_TRANSFER_HLG : VIDEO_COLOR_TRANSFER_SDR);

	}


	static void ReleaseReader (IMFSourceReader** reader, bool shutDown) {

		// A reader of a network source that stalled takes seconds to release,
		// as Media Foundation waits on it, unless its media source is shut down
		// first, which is safe once no read is in progress
		if (!*reader) return;

		if (shutDown) {

			IMFMediaSource* source = NULL;
			GUID none = {};

			if (SUCCEEDED ((*reader)->GetServiceForStream (MF_SOURCE_READER_MEDIASOURCE, none, IID_PPV_ARGS (&source))) && source) {

				source->Shutdown ();
				source->Release ();

			}

		}

		(*reader)->Release ();
		*reader = NULL;

	}


	static VideoColorTransfer ReadTransfer (IMFMediaType* type) {

		UINT32 transfer = MFGetAttributeUINT32 (type, MF_MT_TRANSFER_FUNCTION, 0);
		if (transfer == TRANSFER_PQ) return VIDEO_COLOR_TRANSFER_PQ;
		if (transfer == TRANSFER_HLG) return VIDEO_COLOR_TRANSFER_HLG;

		// Media Foundation does not say for H.264, so its SPS is read, from the
		// start codes before it or the avcC record it comes in
		GUID subtype = {};
		UINT8* header = NULL;
		UINT32 size = 0;

		if (FAILED (type->GetGUID (MF_MT_SUBTYPE, &subtype)) || subtype != MFVideoFormat_H264 || FAILED (type->GetAllocatedBlob (MF_MT_MPEG_SEQUENCE_HEADER, &header, &size))) {

			return VIDEO_COLOR_TRANSFER_SDR;

		}

		VideoColorTransfer result = VIDEO_COLOR_TRANSFER_SDR;

		if (size > 8 && header[0] == 1) {

			UINT32 length = (header[6] << 8) | header[7];
			if ((header[5] & 31) > 0 && 8 + length <= size && length > 0) result = ReadH264Transfer (header + 8, length);

		} else {

			for (UINT32 i = 0; i + 3 < size; i++) {

				if (header[i] == 0 && header[i + 1] == 0 && header[i + 2] == 1 && (header[i + 3] & 31) == 7) {

					result = ReadH264Transfer (header + i + 3, size - i - 3);
					break;

				}

			}

		}

		CoTaskMemFree (header);
		return result;

	}

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

		unsigned int glTexture;
		HANDLE interop;
		// Locked for OpenGL, as the frame being shown is
		bool locked;
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
	static MFCreateSourceReaderFromByteStreamFunc _MFCreateSourceReaderFromByteStream = 0;
	static MFCreateSourceReaderFromURLFunc _MFCreateSourceReaderFromURL = 0;
	static MFCreateSourceResolverFunc _MFCreateSourceResolver = 0;
	static MFShutdownFunc _MFShutdown = 0;
	static MFStartupFunc _MFStartup = 0;

	static std::once_flag loadFlag;
	static bool loaded = false;


	static HMODULE LoadSystemLibrary (const wchar_t* name) {

		// From the system directory only, so a DLL of the same name beside the
		// application or in the working directory is not loaded instead
		wchar_t path[MAX_PATH];
		UINT length = GetSystemDirectoryW (path, MAX_PATH);
		if (length == 0 || length + wcslen (name) + 2 > MAX_PATH) return NULL;

		path[length] = L'\\';
		wcscpy (path + length + 1, name);
		return LoadLibraryW (path);

	}


	static bool LoadMediaFoundation () {

		std::call_once (loadFlag, [] {

			HMODULE mfplat = LoadSystemLibrary (L"mfplat.dll");
			HMODULE mfreadwrite = LoadSystemLibrary (L"mfreadwrite.dll");

			if (!mfplat || !mfreadwrite) return;

			_MFCreateAttributes = (MFCreateAttributesFunc)GetProcAddress (mfplat, "MFCreateAttributes");
			_MFCreateDXGIDeviceManager = (MFCreateDXGIDeviceManagerFunc)GetProcAddress (mfplat, "MFCreateDXGIDeviceManager");
			_MFCreateMediaType = (MFCreateMediaTypeFunc)GetProcAddress (mfplat, "MFCreateMediaType");
			_MFShutdown = (MFShutdownFunc)GetProcAddress (mfplat, "MFShutdown");
			_MFStartup = (MFStartupFunc)GetProcAddress (mfplat, "MFStartup");
			_MFCreateSourceReaderFromURL = (MFCreateSourceReaderFromURLFunc)GetProcAddress (mfreadwrite, "MFCreateSourceReaderFromURL");
			_MFCreateSourceReaderFromByteStream = (MFCreateSourceReaderFromByteStreamFunc)GetProcAddress (mfreadwrite, "MFCreateSourceReaderFromByteStream");
			_MFCreateSourceResolver = (MFCreateSourceResolverFunc)GetProcAddress (mfplat, "MFCreateSourceResolver");

			HMODULE d3d11 = LoadSystemLibrary (L"d3d11.dll");
			if (d3d11) _D3D11CreateDevice = (PFN_D3D11_CREATE_DEVICE)GetProcAddress (d3d11, "D3D11CreateDevice");

			loaded = (_MFCreateAttributes && _MFCreateMediaType && _MFShutdown && _MFStartup && _MFCreateSourceReaderFromURL);

		});

		return loaded;

	}


	struct MFThreadApartment {

		bool initialized;

		MFThreadApartment () : initialized (false) {}
		~MFThreadApartment () { if (initialized) CoUninitialize (); }

	};


	static void InitializeCOM () {

		// Media Foundation objects are free-threaded, so each decoding thread
		// joins the multithreaded apartment until it ends
		static thread_local MFThreadApartment apartment;

		if (!apartment.initialized) {

			apartment.initialized = SUCCEEDED (CoInitializeEx (NULL, COINIT_MULTITHREADED));

		}

	}


	static void UseMultithreadedApartment () {

		// The application's threads are not put in an apartment, which would
		// stop one joining the apartment it needs later, such as for drag and
		// drop. The multithreaded apartment is kept instead, which threads that
		// are in none use, and other threads use Media Foundation from theirs.
		static std::once_flag flag;

		std::call_once (flag, [] {

			typedef HRESULT (WINAPI *CoIncrementMTAUsageFunc) (void**);
			HMODULE ole32 = GetModuleHandleW (L"ole32.dll");
			CoIncrementMTAUsageFunc increment = ole32 ? (CoIncrementMTAUsageFunc)GetProcAddress (ole32, "CoIncrementMTAUsage") : NULL;
			void* cookie = NULL;

			if (increment && SUCCEEDED (increment (&cookie))) return;

			// Windows 7 keeps the apartment with a thread that stays in it
			std::mutex mutex;
			std::condition_variable condition;
			bool ready = false;

			std::thread ([&mutex, &condition, &ready] {

				CoInitializeEx (NULL, COINIT_MULTITHREADED);

				{
					std::lock_guard<std::mutex> lock (mutex);
					ready = true;
				}

				condition.notify_one ();
				Sleep (INFINITE);

			}).detach ();

			std::unique_lock<std::mutex> lock (mutex);
			condition.wait (lock, [&ready] { return ready; });

		});

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


	// The connection a reader reads through, which closing and seeking give up
	// when it waits on a stalled network source
	struct MFConnection {

		MFConnection () : busy (false), byteStream (NULL), cancelCookie (NULL), cancelled (false), reopen (false), reopenPosition (0), resolver (NULL) {}

		// Reading or opening, under the stream mutex
		bool busy;

		IMFByteStream* byteStream;
		IUnknown* cancelCookie;
		std::atomic<bool> cancelled;

		// Given up by a seek, so the reader opens again from reopenPosition
		std::atomic<bool> reopen;
		LONGLONG reopenPosition;

		IMFSourceResolver* resolver;

	};


	// Receives the byte stream a source resolver opens, which a cancelled open
	// may still deliver after the reader stopped waiting for it
	class MFResolveCallback : public IMFAsyncCallback {


		public:

			MFResolveCallback (IMFSourceResolver* resolver) : object (NULL), references (1), resolver (resolver), result (E_PENDING) {

				resolver->AddRef ();
				done = CreateEventW (NULL, TRUE, FALSE, NULL);

			}

			~MFResolveCallback () {

				if (object) object->Release ();
				if (done) CloseHandle (done);
				resolver->Release ();

			}

			STDMETHODIMP QueryInterface (REFIID riid, void** value) {

				if (riid == __uuidof (IMFAsyncCallback) || riid == __uuidof (IUnknown)) {

					*value = static_cast<IMFAsyncCallback*> (this);
					AddRef ();
					return S_OK;

				}

				*value = NULL;
				return E_NOINTERFACE;

			}

			STDMETHODIMP_(ULONG) AddRef () { return InterlockedIncrement (&references); }

			STDMETHODIMP_(ULONG) Release () {

				ULONG count = InterlockedDecrement (&references);
				if (count == 0) delete this;
				return count;

			}

			STDMETHODIMP GetParameters (DWORD* flags, DWORD* queue) { return E_NOTIMPL; }

			STDMETHODIMP Invoke (IMFAsyncResult* asyncResult) {

				MF_OBJECT_TYPE type = MF_OBJECT_INVALID;
				result = resolver->EndCreateObjectFromURL (asyncResult, &type, &object);
				SetEvent (done);
				return S_OK;

			}

			// Once done is set
			IUnknown* TakeObject () {

				IUnknown* value = SUCCEEDED (result) ? object : NULL;
				if (!value && object) object->Release ();
				object = NULL;
				return value;

			}

			HANDLE done;


		private:

			IUnknown* object;
			LONG references;
			IMFSourceResolver* resolver;
			HRESULT result;


	};


	class MFVideoBackend : public VideoBackend {


		public:

			MFVideoBackend ();
			~MFVideoBackend ();

			virtual void Close ();
			virtual VideoDecodeResult DecodeAudio (std::vector<unsigned char>* pcm, double* time);
			virtual VideoDecodeResult DecodeVideo (VideoPlanes* planes, double* time, double* duration);
			virtual void Interrupt ();
			virtual bool Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info);
			virtual void PrepareSeek ();
			virtual bool Seek (double time);

		private:

			void ClearStaging ();
			bool CopyToStaging (IMFSample* sample, LONGLONG timestamp, LONGLONG sampleDuration);
			bool CreateDeviceManager ();
			bool CreateProcessor (UINT inputWidth, UINT inputHeight);
			IMFSourceReader* CreateReader (IMFAttributes* attributes, MFConnection* connection);
			void GetPlanes (VideoPlanes* planes, BYTE* data, int pitch, int lumaRows);
			void GiveUp (MFConnection* connection);
			VideoDecodeResult MapStaging (VideoPlanes* planes, double* time, double* duration);
			bool OpenAudio ();
			bool OpenVideo (bool hardware);
			void ReadAudioFormat ();
			bool OpenVideoReader (bool hardware, bool advanced, bool keepDevice = false);
			HRESULT ReadSample (IMFSourceReader* reader, DWORD stream, MFConnection* connection, DWORD* flags, LONGLONG* timestamp, IMFSample** sample);
			void ReadVideoFormat ();
			void ReleaseDeviceManager ();
			void ReleaseProcessor ();
			VideoDecodeResult ReopenAudio ();
			VideoDecodeResult ReopenVideo ();
			IUnknown* ResolveURL (IMFSourceResolver* resolver, MFConnection* connection);
			bool SetBusy (MFConnection* connection, bool busy);
			void SetByteStream (MFConnection* connection, IMFByteStream* value);
			bool SwitchToSoftware ();
			void UnlockVideo ();

			virtual VideoDecodeResult DecodeVideoTexture (VideoTextureFrame** frame, double* time, double* duration);
			virtual unsigned int LockTexture (VideoTextureFrame* frame);
			virtual void ReleaseTextureFrame (VideoTextureFrame* frame);
			virtual void ReleaseOrphans ();
			virtual void ReleaseTextures ();
			virtual bool SupportsTextures ();
			virtual void UnlockTexture (VideoTextureFrame* frame);

			int audioChannels;
			VideoAudioConverter audioConverter;
			int audioPacketChannels;
			int audioPacketRate;
			MFConnection audioConnection;
			IMFSourceReader* audioReader;
			int audioSampleRate;
			int audioSourceChannels;
			bool audioStreamFound;
			int bufferHeight;
			int bufferWidth;
			bool canSeek;
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
			ID3D11Query* outputQuery;
			MFOutputTexture outputs[OUTPUT_TEXTURES];
			ID3D11VideoProcessor* processor;
			ID3D11VideoProcessorEnumerator* processorEnumerator;
			UINT processorHeight;
			UINT processorWidth;
			IMFDXGIDeviceManager* deviceManager;
			double frameRate;
			VideoColorTransfer frameTransfer;
			bool fullRange;
			bool hardwareActive;
			std::map<std::pair<ID3D11Texture2D*, UINT>, ID3D11VideoProcessorInputView*> inputViews;
			std::atomic<bool> interrupted;
			HANDLE interopDevice;
			void* interopContext;
			bool interopFailed;
			LONGLONG lastFrameTime;
			IMF2DBuffer* locked2D;
			IMFMediaBuffer* lockedBuffer;
			double pixelAspectRatio;
			int rotation;
			LONGLONG skipUntil;
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
			bool network;
			std::condition_variable readCondition;
			std::atomic<bool> seeking;
			bool started;
			std::mutex streamMutex;
			std::wstring url;
			bool videoAdvanced;
			bool videoEnded;
			ID3D11VideoContext* videoContext;
			ID3D11VideoDevice* videoDevice;
			LONGLONG videoPosition;
			MFConnection videoConnection;
			IMFSourceReader* videoReader;
			bool videoStreamFound;


	};


	MFVideoBackend::MFVideoBackend () {

		audioChannels = 0;
		audioPacketChannels = 0;
		audioPacketRate = 0;
		audioReader = NULL;
		audioSampleRate = 0;
		audioSourceChannels = 0;
		audioStreamFound = false;
		bufferHeight = 0;
		bufferWidth = 0;
		canSeek = true;
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
		interopContext = NULL;
		interopDevice = NULL;
		interopFailed = false;
		interrupted = false;
		lastFrameTime = -1;
		locked2D = NULL;
		lockedBuffer = NULL;
		outputQuery = NULL;
		pixelAspectRatio = 0;
		processor = NULL;
		processorEnumerator = NULL;
		processorHeight = 0;
		processorWidth = 0;
		rotation = 0;
		skipUntil = -1;
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
		frameTransfer = VIDEO_COLOR_TRANSFER_SDR;
		network = false;
		seeking = false;
		videoAdvanced = false;
		videoReader = NULL;
		videoStreamFound = false;

		for (int i = 0; i < STAGING_TEXTURES; i++) staging[i] = NULL;

		for (int i = 0; i < OUTPUT_TEXTURES; i++) {

			outputs[i].glTexture = 0;
			outputs[i].interop = NULL;
			outputs[i].locked = false;
			outputs[i].texture = NULL;
			outputs[i].view = NULL;
			outputFrames[i].index = i;

		}

		UseMultithreadedApartment ();
		started = SUCCEEDED (_MFStartup (MF_VERSION, MFSTARTUP_FULL));

	}


	#ifdef LIME_VIDEO_WGL_INTEROP
	// Textures shared with OpenGL by a backend closed away from the GL thread.
	// The device is kept so the interop objects can still be released.
	struct MFOrphan {

		void* context;
		ID3D11Device* device;
		HANDLE interopDevice;
		std::vector<HANDLE> interops;
		std::vector<unsigned int> glTextures;
		std::vector<bool> locked;
		std::vector<ID3D11Texture2D*> textures;

	};

	// Never destroyed, like the other video code's, as threads can still be
	// closing videos while static destructors run
	static std::mutex* orphanMutex = new std::mutex ();
	static std::vector<MFOrphan>* orphans = new std::vector<MFOrphan> ();
	#endif


	void MFVideoBackend::ReleaseOrphans () {

		#ifdef LIME_VIDEO_WGL_INTEROP
		std::vector<MFOrphan> list;

		{
			std::lock_guard<std::mutex> lock (*orphanMutex);
			if (orphans->empty ()) return;
			list.swap (*orphans);
		}

		void* context = (void*)wglGetCurrentContext ();

		for (size_t i = 0; i < list.size (); i++) {

			MFOrphan& orphan = list[i];

			// Objects from a context that is no longer current are left with it
			bool current = orphan.interopDevice && orphan.context == context;

			for (size_t j = 0; j < orphan.interops.size (); j++) {

				// The frame shown when the backend closed is still locked, and is
				// unlocked first, as closing on the GL thread does
				if (current && orphan.interops[j] && orphan.locked[j]) _wglDXUnlockObjectsNV (orphan.interopDevice, 1, &orphan.interops[j]);
				if (current && orphan.interops[j]) _wglDXUnregisterObjectNV (orphan.interopDevice, orphan.interops[j]);
				if (current && orphan.glTextures[j]) glDeleteTextures (1, &orphan.glTextures[j]);
				if (orphan.textures[j]) orphan.textures[j]->Release ();

			}

			if (current) _wglDXCloseDeviceNV (orphan.interopDevice);
			if (orphan.device) orphan.device->Release ();

		}
		#endif

	}


	MFVideoBackend::~MFVideoBackend () {

		Close ();

		if (started) _MFShutdown ();

	}


	void MFVideoBackend::Close () {

		// Closing away from the GL thread queues the textures it shares with
		// OpenGL, rather than using them with the next device
		#ifdef LIME_VIDEO_WGL_INTEROP
		MFOrphan orphan;
		orphan.context = interopContext;
		orphan.device = NULL;
		orphan.interopDevice = interopDevice;
		#endif

		for (int i = 0; i < OUTPUT_TEXTURES; i++) {

			if (outputs[i].interop) {

				#ifdef LIME_VIDEO_WGL_INTEROP
				orphan.interops.push_back (outputs[i].interop);
				orphan.glTextures.push_back (outputs[i].glTexture);
				orphan.locked.push_back (outputs[i].locked);
				orphan.textures.push_back (outputs[i].texture);
				#endif

				outputs[i].glTexture = 0;
				outputs[i].interop = NULL;
				outputs[i].locked = false;
				outputs[i].texture = NULL;

			}

		}

		#ifdef LIME_VIDEO_WGL_INTEROP
		if (orphan.interopDevice || !orphan.interops.empty ()) {

			if (device) {

				device->AddRef ();
				orphan.device = device;

			}

			std::lock_guard<std::mutex> lock (*orphanMutex);
			orphans->push_back (orphan);

		}
		#endif

		interopContext = NULL;
		interopDevice = NULL;
		interopFailed = false;

		UnlockVideo ();
		ReleaseReader (&videoReader, network);
		ReleaseReader (&audioReader, network);

		SetByteStream (&audioConnection, NULL);
		SetByteStream (&videoConnection, NULL);
		audioConnection.cancelled = false;
		audioConnection.reopen = false;
		videoConnection.cancelled = false;
		videoConnection.reopen = false;
		frameTransfer = VIDEO_COLOR_TRANSFER_SDR;
		interrupted = false;
		network = false;
		seeking = false;

		ReleaseDeviceManager ();

		audioChannels = 0;
		audioConverter.Reset ();
		audioPacketChannels = 0;
		audioPacketRate = 0;
		audioSampleRate = 0;
		audioSourceChannels = 0;
		audioStreamFound = false;
		canSeek = true;
		frameRate = 0;
		hardwareActive = false;
		lastFrameTime = -1;
		pixelAspectRatio = 0;
		rotation = 0;
		skipUntil = -1;
		stagingFailed = false;
		stagingPrimed = false;
		texturesFailed = false;
		videoEnded = false;
		videoPosition = 0;
		videoStreamFound = false;

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


	IMFSourceReader* MFVideoBackend::CreateReader (IMFAttributes* attributes, MFConnection* connection) {

		// Each reader reads its own byte stream, which is kept so Interrupt and
		// PrepareSeek can close it. The resolver opens files and URLs as Media
		// Foundation does.
		IMFByteStream* byteStream = NULL;
		IMFSourceResolver* resolver = NULL;

		if (_MFCreateSourceResolver && _MFCreateSourceReaderFromByteStream && SUCCEEDED (_MFCreateSourceResolver (&resolver))) {

			IUnknown* object = ResolveURL (resolver, connection);

			if (object) {

				object->QueryInterface (IID_PPV_ARGS (&byteStream));
				object->Release ();

			}

			resolver->Release ();

		}

		IMFSourceReader* reader = NULL;

		if (byteStream) {

			// The byte stream is kept first, so a source that stalls while the
			// reader opens can be given up too
			SetByteStream (connection, byteStream);

			if (FAILED (_MFCreateSourceReaderFromByteStream (byteStream, attributes, &reader))) {

				reader = NULL;
				SetByteStream (connection, NULL);

			}

		}

		if (!reader && (connection->cancelled || FAILED (_MFCreateSourceReaderFromURL (url.c_str (), attributes, &reader)))) {

			return NULL;

		}

		return reader;

	}


	static bool GetSharedDevice (ID3D11Device** device, IMFDXGIDeviceManager** deviceManager) {

		// One device serves every video for the life of the process. Creating one
		// for each video takes tens of milliseconds, and releasing one ends the
		// driver's threads, which Neko's collector, as it tracks every thread in
		// the process, can abort on when it happens during a collection.
		static std::mutex mutex;
		static ID3D11Device* sharedDevice = NULL;
		static IMFDXGIDeviceManager* sharedManager = NULL;

		std::lock_guard<std::mutex> lock (mutex);

		if (sharedDevice && sharedDevice->GetDeviceRemovedReason () != S_OK) {

			// A device lost to a driver reset or update is replaced. Videos using
			// it keep their references until they close.
			sharedManager->Release ();
			sharedDevice->Release ();
			sharedManager = NULL;
			sharedDevice = NULL;

		}

		if (!sharedDevice) {

			if (!_D3D11CreateDevice || !_MFCreateDXGIDeviceManager) return false;

			static const D3D_FEATURE_LEVEL levels[] = { D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_1, D3D_FEATURE_LEVEL_10_0, D3D_FEATURE_LEVEL_9_3 };

			UINT flags = D3D11_CREATE_DEVICE_VIDEO_SUPPORT | D3D11_CREATE_DEVICE_BGRA_SUPPORT;
			ID3D11Device* created = NULL;
			HRESULT hr = _D3D11CreateDevice (NULL, D3D_DRIVER_TYPE_HARDWARE, NULL, flags, levels, ARRAYSIZE (levels), D3D11_SDK_VERSION, &created, NULL, NULL);

			if (hr == E_INVALIDARG) {

				// Windows 7 without the platform update does not know 11.1
				hr = _D3D11CreateDevice (NULL, D3D_DRIVER_TYPE_HARDWARE, NULL, flags, levels + 1, ARRAYSIZE (levels) - 1, D3D11_SDK_VERSION, &created, NULL, NULL);

			}

			if (FAILED (hr) || !created) return false;

			// Media Foundation and every video use the device from their own threads
			ID3D10Multithread* multithread = NULL;

			if (SUCCEEDED (created->QueryInterface (IID_PPV_ARGS (&multithread)))) {

				multithread->SetMultithreadProtected (TRUE);
				multithread->Release ();

			}

			UINT token = 0;
			IMFDXGIDeviceManager* manager = NULL;

			if (FAILED (_MFCreateDXGIDeviceManager (&token, &manager)) || FAILED (manager->ResetDevice (created, token))) {

				if (manager) manager->Release ();
				created->Release ();
				return false;

			}

			sharedDevice = created;
			sharedManager = manager;

		}

		sharedDevice->AddRef ();
		sharedManager->AddRef ();
		*device = sharedDevice;
		*deviceManager = sharedManager;
		return true;

	}


	bool MFVideoBackend::CreateDeviceManager () {

		if (deviceManager) return true;
		if (!GetSharedDevice (&device, &deviceManager)) return false;

		device->GetImmediateContext (&context);
		return true;

	}


	VideoDecodeResult MFVideoBackend::DecodeAudio (std::vector<unsigned char>* pcm, double* time) {

		InitializeCOM ();

		if (audioConnection.reopen) {

			VideoDecodeResult result = ReopenAudio ();
			if (result != VIDEO_DECODE_OK) return result;

		}

		if (!audioReader) return VIDEO_DECODE_END;

		while (true) {

			DWORD flags = 0;
			LONGLONG timestamp = 0;
			IMFSample* sample = NULL;

			HRESULT hr = ReadSample (audioReader, MF_SOURCE_READER_FIRST_AUDIO_STREAM, &audioConnection, &flags, &timestamp, &sample);

			if (FAILED (hr) || (flags & MF_SOURCE_READERF_ERROR)) {

				if (sample) sample->Release ();

				// A seek gave up on this read, or it waits for one, and reading
				// carries on after it
				return audioConnection.reopen || seeking ? VIDEO_DECODE_AGAIN : VIDEO_DECODE_ERROR;

			}

			if (flags & MF_SOURCE_READERF_ENDOFSTREAM) {

				if (sample) sample->Release ();
				return VIDEO_DECODE_END;

			}

			// A stream can change its rate or channels partway, such as HE-AAC
			// that only shows its full rate once decoding starts
			if (flags & MF_SOURCE_READERF_CURRENTMEDIATYPECHANGED) ReadAudioFormat ();

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

			// Audio is given in the format it opened with
			if (audioPacketChannels == audioChannels && audioPacketRate == audioSampleRate) {

				pcm->insert (pcm->end (), data, data + length);

			} else if (audioPacketChannels > 0 && audioPacketRate > 0) {

				ConvertAudio ((const short*)data, length / (audioPacketChannels * 2), audioPacketChannels, audioPacketRate, audioChannels, audioSampleRate, &audioConverter, pcm);

			}

			buffer->Unlock ();
			buffer->Release ();

			return VIDEO_DECODE_OK;

		}

	}


	VideoDecodeResult MFVideoBackend::DecodeVideo (VideoPlanes* planes, double* time, double* duration) {

		UnlockVideo ();
		InitializeCOM ();

		if (videoConnection.reopen) {

			VideoDecodeResult result = ReopenVideo ();
			if (result != VIDEO_DECODE_OK) return result;

		}

		if (!videoReader) return VIDEO_DECODE_END;

		while (true) {

			// The first frame after opening or seeking is mapped straight away, so
			// only frames that follow it wait for the pipeline
			if (!stagingQueue.empty () && (stagingQueue.size () >= (size_t)STAGING_DELAY || videoEnded || !stagingPrimed)) {

				stagingPrimed = true;
				VideoDecodeResult result = MapStaging (planes, time, duration);

				// A GPU that is lost, as when its driver restarts, cannot give back
				// the frames it decoded, so decoding carries on in software
				if (result == VIDEO_DECODE_ERROR && hardwareActive && !interrupted && SwitchToSoftware ()) continue;

				return result;

			}

			if (videoEnded) return VIDEO_DECODE_END;

			DWORD flags = 0;
			LONGLONG timestamp = 0;
			IMFSample* sample = NULL;

			HRESULT hr = ReadSample (videoReader, MF_SOURCE_READER_FIRST_VIDEO_STREAM, &videoConnection, &flags, &timestamp, &sample);

			if (FAILED (hr) || (flags & MF_SOURCE_READERF_ERROR)) {

				if (sample) sample->Release ();

				// A seek gave up on this read, or it waits for one, and reading
				// carries on after it
				if (videoConnection.reopen || seeking) return VIDEO_DECODE_AGAIN;

				if (hardwareActive && !interrupted && SwitchToSoftware ()) continue;

				return videoConnection.reopen || seeking ? VIDEO_DECODE_AGAIN : VIDEO_DECODE_ERROR;

			}

			if (flags & MF_SOURCE_READERF_CURRENTMEDIATYPECHANGED) ReadVideoFormat ();

			if (flags & MF_SOURCE_READERF_ENDOFSTREAM) {

				if (sample) sample->Release ();
				videoEnded = true;
				continue;

			}

			if (!sample) continue;

			// After switching to software, decoding restarts from a keyframe, and
			// the frames that were already returned are skipped
			if (skipUntil >= 0) {

				if (timestamp <= skipUntil) {

					sample->Release ();
					continue;

				}

				skipUntil = -1;

			}

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

			lastFrameTime = timestamp;
			videoPosition = timestamp;
			*time = timestamp / 10000000.0;
			*duration = sampleDuration > 0 ? sampleDuration / 10000000.0 : (frameRate > 0 ? 1.0 / frameRate : 0);

			return VIDEO_DECODE_OK;

		}

	}


	void MFVideoBackend::GiveUp (MFConnection* connection) {

		// Closing the byte stream makes a read waiting on a stalled network
		// source fail, and connecting is cancelled
		connection->cancelled = true;
		if (connection->byteStream) connection->byteStream->Close ();
		if (connection->resolver && connection->cancelCookie) connection->resolver->CancelObjectCreation (connection->cancelCookie);

	}


	void MFVideoBackend::Interrupt () {

		// A stream waiting on a stalled network source would wait until the
		// connection times out, half a minute later
		interrupted = true;

		std::lock_guard<std::mutex> lock (streamMutex);
		GiveUp (&audioConnection);
		GiveUp (&videoConnection);

	}


	void MFVideoBackend::GetPlanes (VideoPlanes* planes, BYTE* data, int pitch, int lumaRows) {

		planes->colorMatrix = colorMatrix;
		planes->fullRange = fullRange;
		planes->transfer = frameTransfer;
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

		lastFrameTime = stagingTimes[index];
		videoPosition = stagingTimes[index];
		*time = stagingTimes[index] / 10000000.0;
		*duration = stagingDurations[index] > 0 ? stagingDurations[index] / 10000000.0 : (frameRate > 0 ? 1.0 / frameRate : 0);

		return VIDEO_DECODE_OK;

	}


	bool MFVideoBackend::Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info) {

		Close ();

		if (!started || !path || !path[0]) return false;

		UseMultithreadedApartment ();

		url = GetURL (path);
		if (url.empty ()) return false;

		network = url.find (L"://") != std::wstring::npos && url.compare (0, 5, L"file:") != 0;

		info->hasVideo = OpenVideo (hardwareDecoding) || (hardwareDecoding && OpenVideo (false));
		info->hasAudio = OpenAudio ();

		// A stream that was found but cannot be decoded, such as one in a codec
		// that is not installed
		info->videoUnsupported = !info->hasVideo && videoStreamFound;
		info->audioUnsupported = !info->hasAudio && audioStreamFound;

		if (!info->hasVideo && !info->hasAudio) return false;

		IMFSourceReader* reader = videoReader ? videoReader : audioReader;
		PROPVARIANT duration;
		PropVariantInit (&duration);

		if (SUCCEEDED (reader->GetPresentationAttribute (MF_SOURCE_READER_MEDIASOURCE, MF_PD_DURATION, &duration)) && duration.vt == VT_UI8) {

			info->duration = duration.uhVal.QuadPart / 10000000.0;

		}

		PropVariantClear (&duration);

		PROPVARIANT characteristics;
		PropVariantInit (&characteristics);

		if (SUCCEEDED (reader->GetPresentationAttribute (MF_SOURCE_READER_MEDIASOURCE, MF_SOURCE_READER_MEDIASOURCE_CHARACTERISTICS, &characteristics)) && characteristics.vt == VT_UI4) {

			canSeek = (characteristics.ulVal & MFMEDIASOURCE_CAN_SEEK) != 0;

		}

		PropVariantClear (&characteristics);

		info->audioChannels = audioChannels;
		info->audioSampleRate = audioSampleRate;
		info->frameRate = frameRate;
		info->pixelAspectRatio = info->hasVideo ? pixelAspectRatio : 0;
		info->rotation = info->hasVideo ? rotation : 0;
		info->width = info->hasVideo ? cropWidth : 0;
		info->height = info->hasVideo ? cropHeight : 0;

		return true;

	}


	bool MFVideoBackend::OpenAudio () {

		IMFSourceReader* reader = NULL;

		reader = CreateReader (NULL, &audioConnection);
		if (!reader) return false;

		reader->SetStreamSelection (MF_SOURCE_READER_ALL_STREAMS, FALSE);

		IMFMediaType* nativeType = NULL;

		if (FAILED (reader->SetStreamSelection (MF_SOURCE_READER_FIRST_AUDIO_STREAM, TRUE)) || FAILED (reader->GetNativeMediaType (MF_SOURCE_READER_FIRST_AUDIO_STREAM, 0, &nativeType))) {

			reader->Release ();
			return false;

		}

		audioStreamFound = true;
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
		audioConverter.Reset ();
		audioPacketChannels = audioSourceChannels;
		audioPacketRate = audioSampleRate;

		return true;

	}


	void MFVideoBackend::ReadAudioFormat () {

		IMFMediaType* type = NULL;
		if (FAILED (audioReader->GetCurrentMediaType (MF_SOURCE_READER_FIRST_AUDIO_STREAM, &type))) return;

		UINT32 bits = MFGetAttributeUINT32 (type, MF_MT_AUDIO_BITS_PER_SAMPLE, 0);
		UINT32 channels = MFGetAttributeUINT32 (type, MF_MT_AUDIO_NUM_CHANNELS, 0);
		UINT32 sampleRate = MFGetAttributeUINT32 (type, MF_MT_AUDIO_SAMPLES_PER_SECOND, 0);
		type->Release ();

		// A format that cannot be read is dropped, rather than played as noise
		bool readable = (bits == 16 && channels > 0 && channels <= 8 && sampleRate > 0);
		audioPacketChannels = readable ? (int)channels : 0;
		audioPacketRate = readable ? (int)sampleRate : 0;

	}


	bool MFVideoBackend::OpenVideo (bool hardware) {

		if (hardware) return OpenVideoReader (true, true);

		// Software decoding converts frames with the basic video processing, or
		// the advanced processing of Windows 8 and later for what that cannot,
		// such as 10-bit video
		return OpenVideoReader (false, false) || OpenVideoReader (false, true);

	}


	bool MFVideoBackend::OpenVideoReader (bool hardware, bool advanced, bool keepDevice) {

		IMFAttributes* attributes = NULL;
		if (FAILED (_MFCreateAttributes (&attributes, 4))) return false;

		if (hardware && CreateDeviceManager ()) {

			attributes->SetUnknown (MF_SOURCE_READER_D3D_MANAGER, deviceManager);
			attributes->SetUINT32 (MF_SOURCE_READER_ENABLE_ADVANCED_VIDEO_PROCESSING, TRUE);
			attributes->SetUINT32 (MF_READWRITE_ENABLE_HARDWARE_TRANSFORMS, TRUE);

		} else {

			hardware = false;
			attributes->SetUINT32 (advanced ? MF_SOURCE_READER_ENABLE_ADVANCED_VIDEO_PROCESSING : MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING, TRUE);

		}

		IMFSourceReader* reader = CreateReader (attributes, &videoConnection);
		attributes->Release ();

		if (!reader) {

			if (hardware && !keepDevice) ReleaseDeviceManager ();
			return false;

		}

		reader->SetStreamSelection (MF_SOURCE_READER_ALL_STREAMS, FALSE);

		bool configured = false;

		if (SUCCEEDED (reader->SetStreamSelection (MF_SOURCE_READER_FIRST_VIDEO_STREAM, TRUE))) {

			videoStreamFound = true;

			// The advanced video processing turns and stretches frames to show
			// them upright with square pixels, which other platforms leave to the
			// application, so frames are asked for with the stream's own rotation
			// and pixel shape to keep them as they are stored
			UINT32 streamRotation = 0;
			UINT64 streamPixelShape = 0;
			VideoColorTransfer streamTransfer = VIDEO_COLOR_TRANSFER_SDR;
			IMFMediaType* nativeType = NULL;

			if (SUCCEEDED (reader->GetNativeMediaType (MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0, &nativeType))) {

				streamRotation = MFGetAttributeUINT32 (nativeType, MF_MT_VIDEO_ROTATION, 0);
				nativeType->GetUINT64 (MF_MT_PIXEL_ASPECT_RATIO, &streamPixelShape);
				streamTransfer = ReadTransfer (nativeType);
				nativeType->Release ();

			}

			// HDR is shown in standard range. The hardware video processing tone
			// maps PQ well, and is asked to. HLG, which it leaves far too bright,
			// and HDR decoded in software, which is not tone mapped, are asked for
			// as they are, and VideoDecoder tone maps them.
			bool hdr = streamTransfer != VIDEO_COLOR_TRANSFER_SDR;
			bool convertHDR = hardware && streamTransfer == VIDEO_COLOR_TRANSFER_PQ;

			// Frames are asked for progressive, so the video processing
			// deinterlaces interlaced video, unless it cannot
			for (int attempt = 0; attempt < (hdr ? 4 : 2) && !configured; attempt++) {

				IMFMediaType* type = NULL;
				if (FAILED (_MFCreateMediaType (&type))) break;

				bool describeHDR = hdr && attempt < 2;

				type->SetGUID (MF_MT_MAJOR_TYPE, MFMediaType_Video);
				type->SetGUID (MF_MT_SUBTYPE, MFVideoFormat_NV12);
				type->SetUINT32 (MF_MT_VIDEO_ROTATION, streamRotation);
				if (streamPixelShape) type->SetUINT64 (MF_MT_PIXEL_ASPECT_RATIO, streamPixelShape);
				if (attempt % 2 == 0) type->SetUINT32 (MF_MT_INTERLACE_MODE, MFVideoInterlace_Progressive);

				if (describeHDR) {

					type->SetUINT32 (MF_MT_TRANSFER_FUNCTION, convertHDR ? MFVideoTransFunc_709 : (streamTransfer == VIDEO_COLOR_TRANSFER_PQ ? TRANSFER_PQ : TRANSFER_HLG));
					type->SetUINT32 (MF_MT_VIDEO_PRIMARIES, convertHDR ? MFVideoPrimaries_BT709 : PRIMARIES_BT2020);
					type->SetUINT32 (MF_MT_YUV_MATRIX, convertHDR ? MFVideoTransferMatrix_BT709 : MATRIX_BT2020);

				}

				configured = SUCCEEDED (reader->SetCurrentMediaType (MF_SOURCE_READER_FIRST_VIDEO_STREAM, NULL, type));
				type->Release ();

				// Without asking, hardware video processing converts HDR itself
				if (configured) frameTransfer = (describeHDR ? convertHDR : hardware) ? VIDEO_COLOR_TRANSFER_SDR : streamTransfer;

			}

		}

		if (!configured) {

			reader->Release ();
			if (hardware && !keepDevice) ReleaseDeviceManager ();
			return false;

		}

		videoReader = reader;
		videoAdvanced = advanced;
		hardwareActive = hardware;
		ReadVideoFormat ();

		if (cropWidth <= 0 || cropHeight <= 0) {

			videoReader->Release ();
			videoReader = NULL;
			if (hardware && !keepDevice) ReleaseDeviceManager ();
			return false;

		}

		return true;

	}


	void MFVideoBackend::PrepareSeek () {

		// A stream waiting on a stalled network source would hold up the seek
		// until the connection times out, half a minute later. Reads from a
		// source that is still sending finish soon, and those that have not by
		// then are given up. Their readers open again once the seek is done.
		if (!network || !canSeek) return;

		std::unique_lock<std::mutex> lock (streamMutex);
		seeking = true;
		readCondition.wait_for (lock, std::chrono::milliseconds (SEEK_WAIT_MS), [this] { return !audioConnection.busy && !videoConnection.busy; });

		if (audioConnection.busy) {

			audioConnection.reopen = true;
			GiveUp (&audioConnection);

		}

		if (videoConnection.busy) {

			videoConnection.reopen = true;
			GiveUp (&videoConnection);

		}

	}


	HRESULT MFVideoBackend::ReadSample (IMFSourceReader* reader, DWORD stream, MFConnection* connection, DWORD* flags, LONGLONG* timestamp, IMFSample** sample) {

		if (!SetBusy (connection, true)) return E_ABORT;
		HRESULT hr = reader->ReadSample (stream, 0, NULL, flags, timestamp, sample);
		SetBusy (connection, false);
		return hr;

	}


	VideoDecodeResult MFVideoBackend::ReopenAudio () {

		// A seek gave up on a read that waited on a stalled network source, so
		// the reader opens again, at the time seeked to, and plays on in the
		// format it opened with
		audioConnection.reopen = false;

		if (!SetBusy (&audioConnection, true)) {

			audioConnection.reopen = true;
			return VIDEO_DECODE_AGAIN;

		}

		ReleaseReader (&audioReader, true);
		SetByteStream (&audioConnection, NULL);

		int channels = audioChannels;
		int sampleRate = audioSampleRate;
		bool opened = OpenAudio ();
		SetBusy (&audioConnection, false);

		if (!opened || audioConnection.reopen) {

			// One that cannot open is tried again at the next seek
			bool again = audioConnection.reopen;
			audioConnection.reopen = true;

			if (audioReader) {

				audioReader->Release ();
				audioReader = NULL;

			}

			return again ? VIDEO_DECODE_AGAIN : VIDEO_DECODE_ERROR;

		}

		audioChannels = channels;
		audioSampleRate = sampleRate;

		PROPVARIANT position;
		PropVariantInit (&position);
		position.vt = VT_I8;
		position.hVal.QuadPart = audioConnection.reopenPosition;
		audioReader->SetCurrentPosition (TIME_FORMAT_100NS, position);

		return VIDEO_DECODE_OK;

	}


	VideoDecodeResult MFVideoBackend::ReopenVideo () {

		// A seek gave up on a read that waited on a stalled network source, so
		// the reader opens again as it was, at the time seeked to. The device
		// stays, as OpenGL can still be showing frames from its textures.
		videoConnection.reopen = false;

		if (!SetBusy (&videoConnection, true)) {

			videoConnection.reopen = true;
			return VIDEO_DECODE_AGAIN;

		}

		ReleaseProcessor ();
		ReleaseReader (&videoReader, true);
		SetByteStream (&videoConnection, NULL);
		bool opened = OpenVideoReader (hardwareActive, videoAdvanced, true);
		SetBusy (&videoConnection, false);

		if (!opened || videoConnection.reopen) {

			// One that cannot open is tried again at the next seek
			bool again = videoConnection.reopen;
			videoConnection.reopen = true;

			if (videoReader) {

				videoReader->Release ();
				videoReader = NULL;

			}

			return again ? VIDEO_DECODE_AGAIN : VIDEO_DECODE_ERROR;

		}

		PROPVARIANT position;
		PropVariantInit (&position);
		position.vt = VT_I8;
		position.hVal.QuadPart = videoConnection.reopenPosition;
		videoReader->SetCurrentPosition (TIME_FORMAT_100NS, position);

		return VIDEO_DECODE_OK;

	}


	IUnknown* MFVideoBackend::ResolveURL (IMFSourceResolver* resolver, MFConnection* connection) {

		// Connecting waits for the server, which Interrupt and PrepareSeek can
		// cancel, so it is made asynchronously. The wait ends when it is
		// cancelled, whether or not Media Foundation calls back.
		MFResolveCallback* callback = new MFResolveCallback (resolver);
		IUnknown* cookie = NULL;
		IUnknown* object = NULL;

		if (callback->done && SUCCEEDED (resolver->BeginCreateObjectFromURL (url.c_str (), MF_RESOLUTION_BYTESTREAM, NULL, &cookie, callback, NULL))) {

			{
				std::lock_guard<std::mutex> lock (streamMutex);
				connection->cancelCookie = cookie;
				connection->resolver = resolver;
				if (connection->cancelled && cookie) resolver->CancelObjectCreation (cookie);
			}

			DWORD wait = WAIT_TIMEOUT;

			while (!connection->cancelled && (wait = WaitForSingleObject (callback->done, 50)) == WAIT_TIMEOUT) {}

			{
				std::lock_guard<std::mutex> lock (streamMutex);
				connection->cancelCookie = NULL;
				connection->resolver = NULL;
			}

			if (cookie) cookie->Release ();
			if (wait == WAIT_OBJECT_0) object = callback->TakeObject ();

		}

		callback->Release ();
		return object;

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

		// Media Foundation gives the rotation that was applied to the picture,
		// counterclockwise, which is undone by turning it as far clockwise. The
		// basic video processing keeps frames as they are stored, and says so.
		// The advanced video processing turns and stretches them to show them
		// upright with square pixels, whatever is asked for, and leaves the
		// rotation out, so only what it leaves undone is reported.
		IMFMediaType* streamType = nativeType ? nativeType : type;
		int streamRotation = (int)MFGetAttributeUINT32 (streamType, MF_MT_VIDEO_ROTATION, 0);
		UINT32 streamWidth = 0;
		UINT32 streamHeight = 0;
		MFGetAttributeSize (streamType, MF_MT_FRAME_SIZE, &streamWidth, &streamHeight);

		UINT32 frameRotation = 0;
		bool quarterTurn = (streamRotation == 90 || streamRotation == 270);
		bool sidesSwapped = cropWidth != cropHeight && abs (cropWidth - (int)streamHeight) <= 16 && abs (cropHeight - (int)streamWidth) <= 16;

		if (SUCCEEDED (type->GetUINT32 (MF_MT_VIDEO_ROTATION, &frameRotation))) {

			rotation = (int)frameRotation;

		} else {

			rotation = quarterTurn && !sidesSwapped ? streamRotation : 0;

		}

		// Frames stretched to square pixels no longer match the stream's size
		bool turned = quarterTurn && rotation == 0;
		int storedWidth = turned ? cropHeight : cropWidth;
		int storedHeight = turned ? cropWidth : cropHeight;
		bool stretched = streamWidth > 0 && streamHeight > 0 && (abs (storedWidth - (int)streamWidth) > 2 || abs (storedHeight - (int)streamHeight) > 16);

		UINT32 pixelWidth = 0;
		UINT32 pixelHeight = 0;
		pixelAspectRatio = !stretched && SUCCEEDED (MFGetAttributeRatio (streamType, MF_MT_PIXEL_ASPECT_RATIO, &pixelWidth, &pixelHeight)) && pixelWidth > 0 && pixelHeight > 0 ? (double)pixelWidth / pixelHeight : 0;

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

		if (outputQuery) {

			outputQuery->Release ();
			outputQuery = NULL;

		}

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

		seeking = false;

		// A source that cannot seek, such as a live stream, is left playing
		if (!canSeek) return false;

		UnlockVideo ();
		lastFrameTime = -1;
		skipUntil = -1;
		stagingPrimed = false;
		stagingQueue.clear ();
		videoEnded = false;

		PROPVARIANT position;
		PropVariantInit (&position);
		position.vt = VT_I8;
		position.hVal.QuadPart = (LONGLONG)(time * 10000000.0);

		bool success = true;

		// A reader that a seek gave up on opens again from the new position
		if (videoConnection.reopen) {

			videoConnection.reopenPosition = position.hVal.QuadPart;
			videoPosition = position.hVal.QuadPart;

		} else if (videoReader) {

			success = SUCCEEDED (videoReader->SetCurrentPosition (TIME_FORMAT_100NS, position)) && success;
			videoPosition = position.hVal.QuadPart;

		}

		if (audioConnection.reopen) {

			audioConnection.reopenPosition = position.hVal.QuadPart;

		} else if (audioReader) {

			success = SUCCEEDED (audioReader->SetCurrentPosition (TIME_FORMAT_100NS, position)) && success;

		}

		audioConverter.Reset ();
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
			desc.MiscFlags = D3D11_RESOURCE_MISC_SHARED;

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
		InitializeCOM ();

		if (videoConnection.reopen) {

			VideoDecodeResult result = ReopenVideo ();
			if (result != VIDEO_DECODE_OK) return result;

		}

		if (!videoReader) return VIDEO_DECODE_END;

		while (true) {

			DWORD flags = 0;
			LONGLONG timestamp = 0;
			IMFSample* sample = NULL;

			HRESULT hr = ReadSample (videoReader, MF_SOURCE_READER_FIRST_VIDEO_STREAM, &videoConnection, &flags, &timestamp, &sample);

			if (FAILED (hr) || (flags & MF_SOURCE_READERF_ERROR)) {

				if (sample) sample->Release ();

				// A seek gave up on this read, or it waits for one, and reading
				// carries on after it
				if (videoConnection.reopen || seeking) return VIDEO_DECODE_AGAIN;

				// Continuing in software means decoding into memory from here on
				if (hardwareActive && !interrupted && SwitchToSoftware ()) return VIDEO_DECODE_OK;

				return videoConnection.reopen || seeking ? VIDEO_DECODE_AGAIN : VIDEO_DECODE_ERROR;

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

						// OpenGL samples the shared texture through another API, so wait
						// for the GPU to finish writing it before the frame is queued
						if (!outputQuery) {

							D3D11_QUERY_DESC queryDesc = {};
							queryDesc.Query = D3D11_QUERY_EVENT;
							device->CreateQuery (&queryDesc, &outputQuery);

						}

						if (outputQuery) {

							context->End (outputQuery);
							context->Flush ();
							BOOL done = FALSE;
							while (context->GetData (outputQuery, &done, sizeof (done), 0) == S_FALSE) std::this_thread::yield ();

						} else {

							context->Flush ();

						}

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

			lastFrameTime = timestamp;
			videoPosition = timestamp;
			*time = timestamp / 10000000.0;
			*duration = sampleDuration > 0 ? sampleDuration / 10000000.0 : (frameRate > 0 ? 1.0 / frameRate : 0);

			return VIDEO_DECODE_OK;

		}

	}


	unsigned int MFVideoBackend::LockTexture (VideoTextureFrame* frame) {

		#ifdef LIME_VIDEO_WGL_INTEROP
		MFOutputTexture& output = outputs[((MFTextureFrame*)frame)->index];
		HGLRC glContext = wglGetCurrentContext ();

		if (interopDevice && glContext != interopContext) {

			// Another context is current, such as another window's, where the
			// textures shared with the first one do not exist, so they are shared
			// again and the first context keeps its own until it is deleted
			for (int i = 0; i < OUTPUT_TEXTURES; i++) {

				outputs[i].glTexture = 0;
				outputs[i].interop = NULL;
				outputs[i].locked = false;

			}

			interopDevice = NULL;
			interopFailed = false;

		}

		if (!interopDevice) {

			if (interopFailed || !glContext) return 0;

			_wglDXOpenDeviceNV = (WGLDXOpenDeviceFunc)wglGetProcAddress ("wglDXOpenDeviceNV");
			_wglDXCloseDeviceNV = (WGLDXCloseDeviceFunc)wglGetProcAddress ("wglDXCloseDeviceNV");
			_wglDXRegisterObjectNV = (WGLDXRegisterObjectFunc)wglGetProcAddress ("wglDXRegisterObjectNV");
			_wglDXUnregisterObjectNV = (WGLDXUnregisterObjectFunc)wglGetProcAddress ("wglDXUnregisterObjectNV");
			_wglDXLockObjectsNV = (WGLDXLockObjectsFunc)wglGetProcAddress ("wglDXLockObjectsNV");
			_wglDXUnlockObjectsNV = (WGLDXUnlockObjectsFunc)wglGetProcAddress ("wglDXUnlockObjectsNV");

			if (_wglDXOpenDeviceNV && _wglDXCloseDeviceNV && _wglDXRegisterObjectNV && _wglDXUnregisterObjectNV && _wglDXLockObjectsNV && _wglDXUnlockObjectsNV) {

				interopDevice = _wglDXOpenDeviceNV (device);
				interopContext = glContext;

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
			output.locked = true;

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

		if (!_wglDXLockObjectsNV (interopDevice, 1, &output.interop)) return 0;
		output.locked = true;
		return output.glTexture;
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
		bool current = interopDevice && wglGetCurrentContext () == interopContext;

		for (int i = 0; i < OUTPUT_TEXTURES; i++) {

			if (outputs[i].interop) {

				if (current && outputs[i].locked) _wglDXUnlockObjectsNV (interopDevice, 1, &outputs[i].interop);
				if (current) _wglDXUnregisterObjectNV (interopDevice, outputs[i].interop);
				outputs[i].interop = NULL;
				outputs[i].locked = false;

			}

			if (outputs[i].glTexture) {

				if (current) glDeleteTextures (1, &outputs[i].glTexture);
				outputs[i].glTexture = 0;

			}

		}

		// Objects from a context that is no longer current are left with it
		if (interopDevice && wglGetCurrentContext () == interopContext) {

			_wglDXCloseDeviceNV (interopDevice);

		}

		interopContext = NULL;
		interopDevice = NULL;
		#endif

		interopFailed = false;

	}


	bool MFVideoBackend::SetBusy (MFConnection* connection, bool busy) {

		// PrepareSeek waits for reads in progress, and gives up those that wait
		// too long. Reads do not start while a seek waits, and a read that
		// starts after closing has begun is given up.
		std::lock_guard<std::mutex> lock (streamMutex);

		if (busy) {

			if (seeking) return false;
			connection->busy = true;
			connection->cancelled = interrupted.load ();

		} else {

			connection->busy = false;
			readCondition.notify_all ();

		}

		return true;

	}


	void MFVideoBackend::SetByteStream (MFConnection* connection, IMFByteStream* value) {

		// Interrupt and PrepareSeek close the streams from another thread, so a
		// stream that opened after they gave up on its connection is closed now
		std::lock_guard<std::mutex> lock (streamMutex);
		if (connection->byteStream) connection->byteStream->Release ();
		connection->byteStream = value;
		if (value && connection->cancelled) value->Close ();

	}


	bool MFVideoBackend::SupportsTextures () {

		// HDR frames that VideoDecoder tone maps are decoded into memory
		return hardwareActive && device && !texturesFailed && frameTransfer == VIDEO_COLOR_TRANSFER_SDR;

	}


	bool MFVideoBackend::SwitchToSoftware () {

		// Some drivers fail to decode a stream they accepted, and a GPU can be
		// lost, so decoding continues from the same position in software. The
		// device and the textures shared with OpenGL stay until closing, as the
		// GL thread can still be showing frames from them.
		ClearStaging ();
		ReleaseProcessor ();
		videoReader->Release ();
		videoReader = NULL;

		// The advanced video processing turns and stretches frames as the
		// hardware decoding did, so they keep the shape they opened with. A
		// network source is opened again, which a seek can give up.
		if (!SetBusy (&videoConnection, true)) return false;
		bool opened = OpenVideoReader (false, true) || OpenVideoReader (false, false);
		SetBusy (&videoConnection, false);

		if (!opened) return false;

		PROPVARIANT position;
		PropVariantInit (&position);
		position.vt = VT_I8;
		position.hVal.QuadPart = videoPosition;
		videoReader->SetCurrentPosition (TIME_FORMAT_100NS, position);

		// Decoding resumes from the keyframe before, so the frames up to the
		// last one returned are skipped
		skipUntil = lastFrameTime;
		return true;

	}


	void MFVideoBackend::UnlockTexture (VideoTextureFrame* frame) {

		#ifdef LIME_VIDEO_WGL_INTEROP
		MFOutputTexture& output = outputs[((MFTextureFrame*)frame)->index];
		if (interopDevice && output.interop && output.locked) _wglDXUnlockObjectsNV (interopDevice, 1, &output.interop);
		output.locked = false;
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
