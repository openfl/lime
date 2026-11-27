#ifndef LIME_MEDIA_VOICE_CAPTURE_H
#define LIME_MEDIA_VOICE_CAPTURE_H


#include <mutex>
#include <stdint.h>
#include <vector>


namespace lime {


	enum VoiceCaptureProcessing {

		VOICE_CAPTURE_ECHO_CANCELLATION = 1,
		VOICE_CAPTURE_NOISE_SUPPRESSION = 2,
		VOICE_CAPTURE_AUTO_GAIN = 4

	};


	// Microphone capture through the platform's voice processing mode, used in
	// place of OpenAL when an AudioInput asks for echo cancellation, noise
	// suppression or automatic gain control
	class VoiceCapture {


		public:

			// The device name is OpenAL's, or null for the default device.
			// processing asks for VoiceCaptureProcessing flags. Returns null where
			// the platform has no voice processing mode, or the device could not
			// be opened.
			static VoiceCapture* Open (const char* deviceName, int sampleRate, int channels, int bitsPerSample, int bufferFrames, int processing);

			virtual ~VoiceCapture ();

			// Lets the device go; nothing more is captured after it
			virtual void Close () = 0;

			int GetAvailable ();
			// The VoiceCaptureProcessing flags the platform applied
			int GetProcessing ();
			bool IsConnected ();
			int Read (unsigned char* data, int frames);
			virtual bool Start () = 0;
			virtual void Stop () = 0;


		protected:

			VoiceCapture (int channels, int bitsPerSample, int bufferFrames);

			void SetDisconnected ();
			void SetProcessing (int processing);
			// Called before the samples are counted or read, for platforms that are
			// polled for them
			virtual void Update () {}
			// 16-bit samples from the platform, in sourceChannels, converted
			// to the requested channels and bits
			void Write (const int16_t* samples, int frames, int sourceChannels);

			int bitsPerSample;
			int channels;


		private:

			std::vector<unsigned char> buffer;
			int bufferFrames;
			bool connected;
			int frameSize;
			std::mutex mutex;
			int processing;
			int readFrame;
			int storedFrames;


	};


}


#endif
