#include "media/SDLSound.h"
#include <limits.h>
#include <system/System.h>


namespace lime {


	static const Uint32 SDL_SOUND_BUFFER_SIZE = 64 * 1024;


	static Uint32 AlignBufferSize (Uint32 bufferSize, int bytesPerFrame) {

		if (bytesPerFrame <= 0) {

			return bufferSize;

		}

		Uint32 frameSize = (Uint32)bytesPerFrame;
		Uint32 alignedSize = bufferSize - (bufferSize % frameSize);

		if (alignedSize == 0) {

			alignedSize = frameSize;

		}

		return alignedSize;

	}


	static Sound_Sample* CreateSample (Resource* resource) {

		Sound_AudioInfo want = {};
		want.format = AUDIO_S16SYS;
		want.channels = 0;
		want.rate = 0;

		Sound_Sample* sample = NULL;

		if (resource->path) {

			sample = Sound_NewSampleFromFile (resource->path, &want, SDL_SOUND_BUFFER_SIZE);

		} else {

			const Uint8* bytes = reinterpret_cast<const Uint8*> (resource->data->b);
			const Uint32 length = static_cast<Uint32> (resource->data->length);
			sample = Sound_NewSampleFromMem (bytes, length, NULL, &want, SDL_SOUND_BUFFER_SIZE);

		}

		if (!sample) {

			printf ("SDL_sound: %s\n", Sound_GetError ());
			return NULL;

		}

		return sample;

	}


	static bool PrepareSample (Sound_Sample* sample, SDLSoundStreamInfo* streamInfo = NULL) {

		const Sound_AudioInfo& actual = sample->actual;
		const Sound_AudioInfo& output = sample->desired.format ? sample->desired : sample->actual;
		int bitsPerSample = SDL_AUDIO_BITSIZE (output.format);

		if (bitsPerSample <= 0) {

			bitsPerSample = SDL_AUDIO_BITSIZE (AUDIO_S16SYS);

		}

		if (output.channels < 1 || output.channels > 2 || output.rate <= 0 || bitsPerSample <= 0) {

			printf ("SDL_sound: unsupported stream format (channels=%d, rate=%d, bits=%d)\n", output.channels, output.rate, bitsPerSample);
			return false;

		}

		Uint32 decodeBufferSize = AlignBufferSize (SDL_SOUND_BUFFER_SIZE, output.channels * (bitsPerSample / 8));

		if (decodeBufferSize != sample->buffer_size && !Sound_SetBufferSize (sample, decodeBufferSize)) {

			printf ("SDL_sound: %s\n", Sound_GetError ());
			return false;

		}

		if (streamInfo) {

			streamInfo->bitsPerSample = bitsPerSample;
			streamInfo->canSeek = ((sample->flags & SOUND_SAMPLEFLAG_CANSEEK) != 0);
			streamInfo->channels = output.channels;
			streamInfo->duration = Sound_GetDuration (sample);
			streamInfo->sampleRate = output.rate;

		}

		return true;

	}


	bool SDLSound::Decode (Resource* resource, AudioBuffer* audioBuffer) {

		Sound_Sample* sample = CreateSample (resource);

		if (!sample) {

			return false;

		}

		SDLSoundStreamInfo streamInfo;

		if (!PrepareSample (sample, &streamInfo)) {

			Sound_FreeSample (sample);
			return false;

		}

		audioBuffer->bitsPerSample = streamInfo.bitsPerSample;
		audioBuffer->channels = streamInfo.channels;
		audioBuffer->sampleRate = streamInfo.sampleRate;

		int capacity = 0;

		if (streamInfo.duration > 0) {

			Uint64 estimatedSize = (((Uint64)streamInfo.duration * (Uint64)audioBuffer->sampleRate * (Uint64)audioBuffer->channels
				* (Uint64)(audioBuffer->bitsPerSample / 8)) + 999) / 1000;

			if (estimatedSize > 0 && estimatedSize <= INT_MAX) {

				capacity = (int)estimatedSize;

			}

		}

		if (capacity < (int)sample->buffer_size) {

			capacity = (int)sample->buffer_size;

		}

		if (!audioBuffer->data->TryResize (capacity)) {

			printf ("SDL_sound decode error: out of memory\n");
			Sound_FreeSample (sample);
			audioBuffer->data->TryResize (0);
			return false;

		}

		int total = 0;

		for (;;) {

			Uint32 decoded = Sound_Decode (sample);

			if (sample->flags & SOUND_SAMPLEFLAG_ERROR) {

				printf ("SDL_sound decode error: %s\n", Sound_GetError ());
				Sound_FreeSample (sample);
				audioBuffer->data->TryResize (0);
				return false;

			}

			if (decoded == 0) {

				if (sample->flags & SOUND_SAMPLEFLAG_EOF) {

					break;

				}

				if (sample->flags & SOUND_SAMPLEFLAG_EAGAIN) {

					printf ("SDL_sound decode error: decoder requested retry before EOF\n");

				} else {

					printf ("SDL_sound decode error: decode stopped before EOF\n");

				}

				Sound_FreeSample (sample);
				audioBuffer->data->TryResize (0);
				return false;

			}

			Uint64 required = (Uint64)total + decoded;

			if (required > INT_MAX) {

				printf ("SDL_sound decode error: decoded sample too large\n");
				Sound_FreeSample (sample);
				audioBuffer->data->TryResize (0);
				return false;

			}

			if ((int)required > capacity) {

				int newCapacity = capacity;

				if (newCapacity <= 0) {

					newCapacity = (int)sample->buffer_size;

				}

				if (newCapacity <= 0) {

					newCapacity = (int)decoded;

				}

				while (newCapacity < (int)required) {

					if (newCapacity > (INT_MAX / 2)) {

						newCapacity = (int)required;
						break;

					}

					newCapacity *= 2;

				}

				if (!audioBuffer->data->TryResize (newCapacity)) {

					printf ("SDL_sound decode error: out of memory\n");
					Sound_FreeSample (sample);
					audioBuffer->data->TryResize (0);
					return false;

				}

				capacity = newCapacity;

			}

			unsigned char* output = audioBuffer->data->buffer->b;
			memcpy (output + total, sample->buffer, decoded);
			total += (int)decoded;

		}

		if (total != capacity && !audioBuffer->data->TryResize (total)) {

			printf ("SDL_sound decode error: out of memory\n");
			Sound_FreeSample (sample);
			audioBuffer->data->TryResize (0);
			return false;

		}

		Sound_FreeSample (sample);
		return true;

	}


	bool SDLSound::GetStreamInfo (Resource* resource, SDLSoundStreamInfo* streamInfo) {

		if (!streamInfo) {

			return false;

		}

		Sound_Sample* sample = CreateSample (resource);

		if (!sample) {

			return false;

		}

		bool result = PrepareSample (sample, streamInfo);
		Sound_FreeSample (sample);

		if (!result) {

			return false;

		}

		return (streamInfo->duration > 0 || (resource && resource->path != NULL));

	}


	SDLSoundStream* SDLSound::OpenStream (Resource* resource) {

		Sound_Sample* sample = CreateSample (resource);

		if (!sample) {

			return NULL;

		}

		if (!PrepareSample (sample)) {

			Sound_FreeSample (sample);
			return NULL;

		}

		SDLSoundStream* stream = new SDLSoundStream ();
		stream->sample = sample;
		return stream;

	}


	int SDLSound::ReadStream (SDLSoundStream* stream, unsigned char* buffer, int length) {

		if (!stream || !stream->sample || !buffer || length <= 0) {

			return -1;

		}

		Sound_Sample* sample = stream->sample;
		const Sound_AudioInfo& output = sample->desired.format ? sample->desired : sample->actual;
		int bitsPerSample = SDL_AUDIO_BITSIZE (output.format);

		if (bitsPerSample <= 0) {

			bitsPerSample = SDL_AUDIO_BITSIZE (AUDIO_S16SYS);

		}

		Uint32 decodeBufferSize = AlignBufferSize ((Uint32)length, output.channels * (bitsPerSample / 8));

		if (decodeBufferSize > (Uint32)length) {

			decodeBufferSize = (Uint32)length;

		}

		if (decodeBufferSize != sample->buffer_size && !Sound_SetBufferSize (sample, decodeBufferSize)) {

			printf ("SDL_sound stream error: %s\n", Sound_GetError ());
			return -1;

		}

		Uint32 decoded = Sound_Decode (sample);

		if (sample->flags & SOUND_SAMPLEFLAG_ERROR) {

			printf ("SDL_sound stream error: %s\n", Sound_GetError ());
			return -1;

		}

		if (decoded == 0) {

			if (sample->flags & SOUND_SAMPLEFLAG_EOF) {

				return 0;

			}

			printf ("SDL_sound stream error: decode stopped before EOF\n");
			return -1;

		}

		memcpy (buffer, sample->buffer, decoded);
		return (int)decoded;

	}


	bool SDLSound::RewindStream (SDLSoundStream* stream) {

		if (!stream || !stream->sample) {

			return false;

		}

		return (Sound_Rewind (stream->sample) != 0);

	}


	bool SDLSound::SeekStream (SDLSoundStream* stream, int ms) {

		if (!stream || !stream->sample || ms < 0) {

			return false;

		}

		return (Sound_Seek (stream->sample, (Uint32)ms) != 0);

	}


	void SDLSound::CloseStream (SDLSoundStream* stream) {

		if (!stream) {

			return;

		}

		if (stream->sample) {

			Sound_FreeSample (stream->sample);
			stream->sample = NULL;

		}

		delete stream;

	}


}
