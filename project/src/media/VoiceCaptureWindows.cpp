#include <media/VoiceCapture.h>

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <mmdeviceapi.h>
#include <audioclient.h>
#include <initguid.h>
#include <functiondiscoverykeys_devpkey.h>
#include <atomic>
#include <condition_variable>
#include <string>
#include <thread>


namespace lime {


	// IAudioEffectsManager is new in Windows 11, so it is declared here for
	// older SDKs. It tells which effects the system applies to a stream.
	enum VoiceCaptureEffectState {

		VOICE_CAPTURE_EFFECT_OFF = 0,
		VOICE_CAPTURE_EFFECT_ON = 1

	};


	struct VoiceCaptureEffect {

		GUID id;
		BOOL canSetState;
		VoiceCaptureEffectState state;

	};


	struct DECLSPEC_UUID ("4460B3AE-4B44-4527-8676-7548A8ACD260") IVoiceCaptureEffectsManager : public IUnknown {

		virtual HRESULT STDMETHODCALLTYPE RegisterAudioEffectsChangedNotificationCallback (IUnknown* client) = 0;
		virtual HRESULT STDMETHODCALLTYPE UnregisterAudioEffectsChangedNotificationCallback (IUnknown* client) = 0;
		virtual HRESULT STDMETHODCALLTYPE GetAudioEffects (VoiceCaptureEffect** effects, UINT32* numEffects) = 0;
		virtual HRESULT STDMETHODCALLTYPE SetAudioEffectState (GUID effectId, VoiceCaptureEffectState state) = 0;

	};


	static const GUID IID_VoiceCaptureEffectsManager = { 0x4460B3AE, 0x4B44, 0x4527, { 0x86, 0x76, 0x75, 0x48, 0xA8, 0xAC, 0xD2, 0x60 } };
	static const GUID EFFECT_ECHO_CANCELLATION = { 0x6f64adbe, 0x8211, 0x11e2, { 0x8c, 0x70, 0x2c, 0x27, 0xd7, 0xf0, 0x01, 0xfa } };
	static const GUID EFFECT_NOISE_SUPPRESSION = { 0x6f64adbf, 0x8211, 0x11e2, { 0x8c, 0x70, 0x2c, 0x27, 0xd7, 0xf0, 0x01, 0xfa } };
	static const GUID EFFECT_AUTO_GAIN = { 0x6f64adc0, 0x8211, 0x11e2, { 0x8c, 0x70, 0x2c, 0x27, 0xd7, 0xf0, 0x01, 0xfa } };


	template<class T> static void SafeRelease (T** object) {

		if (*object) {

			(*object)->Release ();
			*object = NULL;

		}

	}


	class WASAPIVoiceCapture : public VoiceCapture {


		public:

			WASAPIVoiceCapture (int channels, int bitsPerSample, int bufferFrames) : VoiceCapture (channels, bitsPerSample, bufferFrames) {

				commandEvent = CreateEvent (NULL, FALSE, FALSE, NULL);
				opened = false;
				quit = false;
				ready = false;
				running = false;

			}


			~WASAPIVoiceCapture () {

				Close ();
				CloseHandle (commandEvent);

			}


			void Close () {

				quit = true;
				SetEvent (commandEvent);
				if (thread.joinable ()) thread.join ();
				SetDisconnected ();

			}


			// COM is set up on the capture thread, in its own apartment, whatever the
			// application's main thread uses
			bool Open (const char* deviceName, int sampleRate, int requested) {

				std::string name = deviceName ? deviceName : "";
				thread = std::thread ([this, name, sampleRate, requested] { Run (name, sampleRate, requested); });

				std::unique_lock<std::mutex> lock (readyMutex);
				readyCondition.wait (lock, [this] { return ready; });
				return opened;

			}


			bool Start () {

				running = true;
				SetEvent (commandEvent);
				return IsConnected ();

			}


			void Stop () {

				running = false;
				SetEvent (commandEvent);

			}


		private:

			static std::wstring ToWide (const std::string& text) {

				if (text.empty ()) return L"";
				int length = MultiByteToWideChar (CP_UTF8, 0, text.c_str (), -1, NULL, 0);
				std::wstring result (length > 0 ? length - 1 : 0, L'\0');
				if (length > 1) MultiByteToWideChar (CP_UTF8, 0, text.c_str (), -1, &result[0], length);
				return result;

			}


			// OpenAL Soft names a device "OpenAL Soft on " and its endpoint's name,
			// with " #2" after a repeated name
			static IMMDevice* FindDevice (IMMDeviceEnumerator* enumerator, const std::string& deviceName) {

				IMMDevice* device = NULL;

				if (deviceName.empty ()) {

					enumerator->GetDefaultAudioEndpoint (eCapture, eConsole, &device);
					return device;

				}

				std::wstring wanted = ToWide (deviceName);
				const std::wstring prefix = L"OpenAL Soft on ";
				if (wanted.compare (0, prefix.size (), prefix) == 0) wanted = wanted.substr (prefix.size ());

				IMMDeviceCollection* collection = NULL;
				if (FAILED (enumerator->EnumAudioEndpoints (eCapture, DEVICE_STATE_ACTIVE, &collection))) return NULL;

				UINT count = 0;
				collection->GetCount (&count);

				for (UINT i = 0; i < count && !device; i++) {

					IMMDevice* candidate = NULL;
					if (FAILED (collection->Item (i, &candidate))) continue;

					IPropertyStore* properties = NULL;
					PROPVARIANT value;
					PropVariantInit (&value);

					if (SUCCEEDED (candidate->OpenPropertyStore (STGM_READ, &properties)) && SUCCEEDED (properties->GetValue (PKEY_Device_FriendlyName, &value)) && value.vt == VT_LPWSTR) {

						std::wstring friendlyName = value.pwszVal;

						if (wanted == friendlyName || (wanted.compare (0, friendlyName.size (), friendlyName) == 0 && wanted.compare (friendlyName.size (), 2, L" #") == 0)) {

							device = candidate;
							candidate = NULL;

						}

					}

					PropVariantClear (&value);
					SafeRelease (&properties);
					SafeRelease (&candidate);

				}

				SafeRelease (&collection);
				return device;

			}


			// Turns each effect on or off as asked, where Windows lets it, and returns
			// the ones left on. Before Windows 11 nothing can be told, so none are.
			static int ApplyEffects (IAudioClient* client, int requested) {

				IVoiceCaptureEffectsManager* manager = NULL;
				if (FAILED (client->GetService (IID_VoiceCaptureEffectsManager, (void**)&manager))) return 0;

				const GUID* ids[3] = { &EFFECT_ECHO_CANCELLATION, &EFFECT_NOISE_SUPPRESSION, &EFFECT_AUTO_GAIN };
				const int flags[3] = { VOICE_CAPTURE_ECHO_CANCELLATION, VOICE_CAPTURE_NOISE_SUPPRESSION, VOICE_CAPTURE_AUTO_GAIN };
				int applied = 0;

				VoiceCaptureEffect* effects = NULL;
				UINT32 count = 0;

				if (SUCCEEDED (manager->GetAudioEffects (&effects, &count)) && effects) {

					for (UINT32 i = 0; i < count; i++) {

						for (int j = 0; j < 3; j++) {

							if (!IsEqualGUID (effects[i].id, *ids[j])) continue;

							bool on = effects[i].state == VOICE_CAPTURE_EFFECT_ON;
							bool wanted = (requested & flags[j]) != 0;

							if (on != wanted && effects[i].canSetState) {

								if (SUCCEEDED (manager->SetAudioEffectState (effects[i].id, wanted ? VOICE_CAPTURE_EFFECT_ON : VOICE_CAPTURE_EFFECT_OFF))) on = wanted;

							}

							if (on) applied |= flags[j];

						}

					}

					CoTaskMemFree (effects);

				}

				manager->Release ();
				return applied;

			}


			void Finish (bool success) {

				std::lock_guard<std::mutex> lock (readyMutex);
				opened = success;
				ready = true;
				readyCondition.notify_all ();

			}


			void Run (std::string deviceName, int sampleRate, int requested) {

				HRESULT result = CoInitializeEx (NULL, COINIT_MULTITHREADED);
				bool uninitialize = SUCCEEDED (result);

				IMMDeviceEnumerator* enumerator = NULL;
				IMMDevice* device = NULL;
				IAudioClient2* client = NULL;
				IAudioCaptureClient* capture = NULL;
				HANDLE captureEvent = CreateEvent (NULL, FALSE, FALSE, NULL);
				bool success = false;

				do {

					if (FAILED (CoCreateInstance (__uuidof (MMDeviceEnumerator), NULL, CLSCTX_ALL, __uuidof (IMMDeviceEnumerator), (void**)&enumerator))) break;

					device = FindDevice (enumerator, deviceName);
					if (!device) break;

					// IAudioClient2 is in Windows 8 and later
					if (FAILED (device->Activate (__uuidof (IAudioClient2), CLSCTX_ALL, NULL, (void**)&client))) break;

					// The communications category turns on the system's voice processing
					AudioClientProperties properties = {};
					properties.cbSize = sizeof (properties);
					properties.bIsOffload = FALSE;
					properties.eCategory = AudioCategory_Communications;
					if (FAILED (client->SetClientProperties (&properties))) break;

					WAVEFORMATEX format = {};
					format.wFormatTag = WAVE_FORMAT_PCM;
					format.nChannels = (WORD)channels;
					format.nSamplesPerSec = (DWORD)sampleRate;
					format.wBitsPerSample = 16;
					format.nBlockAlign = (WORD)(channels * 2);
					format.nAvgBytesPerSec = format.nSamplesPerSec * format.nBlockAlign;

					// Windows converts its own format to the one asked for
					DWORD flags = AUDCLNT_STREAMFLAGS_EVENTCALLBACK | AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM | AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY;
					if (FAILED (client->Initialize (AUDCLNT_SHAREMODE_SHARED, flags, 2000000, 0, &format, NULL))) break;
					if (FAILED (client->SetEventHandle (captureEvent))) break;
					if (FAILED (client->GetService (__uuidof (IAudioCaptureClient), (void**)&capture))) break;

					SetProcessing (ApplyEffects (client, requested));
					success = true;

				} while (false);

				Finish (success);

				if (success) {

					HANDLE events[2] = { commandEvent, captureEvent };
					bool started = false;

					while (!quit) {

						DWORD wait = WaitForMultipleObjects (2, events, FALSE, 200);

						if (quit) break;

						if (running != started) {

							result = running ? client->Start () : client->Stop ();
							if (SUCCEEDED (result)) started = running;

						}

						if (!started || (wait != WAIT_OBJECT_0 + 1 && wait != WAIT_TIMEOUT)) continue;

						UINT32 packetFrames = 0;

						while (SUCCEEDED (result = capture->GetNextPacketSize (&packetFrames)) && packetFrames > 0) {

							BYTE* data = NULL;
							UINT32 frames = 0;
							DWORD bufferFlags = 0;

							result = capture->GetBuffer (&data, &frames, &bufferFlags, NULL, NULL);
							if (FAILED (result)) break;

							if (bufferFlags & AUDCLNT_BUFFERFLAGS_SILENT) {

								silence.assign ((size_t)frames * channels, 0);
								Write (&silence[0], (int)frames, channels);

							} else {

								Write ((const int16_t*)data, (int)frames, channels);

							}

							capture->ReleaseBuffer (frames);

						}

						if (result == AUDCLNT_E_DEVICE_INVALIDATED) {

							SetDisconnected ();
							break;

						}

					}

					if (started) client->Stop ();

				} else {

					SetDisconnected ();

				}

				SafeRelease (&capture);
				SafeRelease (&client);
				SafeRelease (&device);
				SafeRelease (&enumerator);
				CloseHandle (captureEvent);

				if (uninitialize) CoUninitialize ();

			}


			HANDLE commandEvent;
			bool opened;
			std::atomic<bool> quit;
			bool ready;
			std::condition_variable readyCondition;
			std::mutex readyMutex;
			std::atomic<bool> running;
			std::vector<int16_t> silence;
			std::thread thread;


	};


	VoiceCapture* VoiceCapture::Open (const char* deviceName, int sampleRate, int channels, int bitsPerSample, int bufferFrames, int processing) {

		if (channels < 1 || channels > 2 || (bitsPerSample != 8 && bitsPerSample != 16) || sampleRate <= 0) return NULL;

		WASAPIVoiceCapture* capture = new WASAPIVoiceCapture (channels, bitsPerSample, bufferFrames);

		if (!capture->Open (deviceName, sampleRate, processing)) {

			delete capture;
			return NULL;

		}

		return capture;

	}


}
