#include <media/VoiceCapture.h>
#include <string.h>


namespace lime {


	VoiceCapture::VoiceCapture (int channels, int bitsPerSample, int bufferFrames) {

		this->channels = channels;
		this->bitsPerSample = bitsPerSample;
		this->bufferFrames = bufferFrames < 256 ? 256 : bufferFrames;

		connected = true;
		frameSize = channels * bitsPerSample / 8;
		processing = 0;
		readFrame = 0;
		storedFrames = 0;

		buffer.resize ((size_t)this->bufferFrames * frameSize);

	}


	VoiceCapture::~VoiceCapture () {}


	int VoiceCapture::GetAvailable () {

		Update ();
		std::lock_guard<std::mutex> lock (mutex);
		return storedFrames;

	}


	int VoiceCapture::GetProcessing () {

		std::lock_guard<std::mutex> lock (mutex);
		return processing;

	}


	bool VoiceCapture::IsConnected () {

		std::lock_guard<std::mutex> lock (mutex);
		return connected;

	}


	int VoiceCapture::Read (unsigned char* data, int frames) {

		Update ();
		std::lock_guard<std::mutex> lock (mutex);

		if (frames > storedFrames) frames = storedFrames;

		for (int i = 0; i < frames; i++) {

			memcpy (data + (size_t)i * frameSize, &buffer[(size_t)readFrame * frameSize], frameSize);
			readFrame = (readFrame + 1) % bufferFrames;

		}

		storedFrames -= frames;
		return frames;

	}


	void VoiceCapture::SetDisconnected () {

		std::lock_guard<std::mutex> lock (mutex);
		connected = false;

	}


	void VoiceCapture::SetProcessing (int processing) {

		std::lock_guard<std::mutex> lock (mutex);
		this->processing = processing;

	}


	void VoiceCapture::Write (const int16_t* samples, int frames, int sourceChannels) {

		std::lock_guard<std::mutex> lock (mutex);

		for (int i = 0; i < frames; i++) {

			const int16_t* source = samples + (size_t)i * sourceChannels;
			int16_t frame[2];

			if (channels == 1) {

				frame[0] = sourceChannels == 1 ? source[0] : (int16_t)(((int)source[0] + (int)source[1]) / 2);

			} else {

				frame[0] = source[0];
				frame[1] = sourceChannels == 1 ? source[0] : source[1];

			}

			// When the application reads too slowly, the oldest frames make way
			if (storedFrames == bufferFrames) {

				readFrame = (readFrame + 1) % bufferFrames;
				storedFrames--;

			}

			int writeFrame = (readFrame + storedFrames) % bufferFrames;
			unsigned char* target = &buffer[(size_t)writeFrame * frameSize];

			for (int channel = 0; channel < channels; channel++) {

				if (bitsPerSample == 8) {

					*target++ = (unsigned char)((frame[channel] >> 8) + 128);

				} else {

					*target++ = (unsigned char)(frame[channel] & 0xFF);
					*target++ = (unsigned char)((frame[channel] >> 8) & 0xFF);

				}

			}

			storedFrames++;

		}

	}


	#if (!defined (HX_WINDOWS) || defined (HX_WINRT)) && !defined (ANDROID) && !defined (HX_MACOS) && !defined (IPHONE)
	VoiceCapture* VoiceCapture::Open (const char* deviceName, int sampleRate, int channels, int bitsPerSample, int bufferFrames, int processing) {

		// Linux leaves echo cancellation to the sound server, as PulseAudio's
		// and PipeWire's echo-cancel modules do
		return NULL;

	}
	#endif


}
