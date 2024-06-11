#include "media/decoders/SDL_sound.h"
#include "SDL_sound.h"
#include <system/System.h>


namespace lime {


	bool SDL_sound::Decode (Resource *resource, AudioBuffer *audioBuffer) {

		Sound_Sample* sample = NULL;

		if (resource->path) {

			sample = Sound_NewSampleFromFile(resource->path, NULL, 65536);

		} else {

			sample = Sound_NewSampleFromMem(resource->data->b, resource->data->length, NULL, NULL, 65536);

		}

		if (!sample) {

			printf("%s\n", Sound_GetError());
			return false;

		}

		audioBuffer->sampleRate = (int)sample->actual.rate;
		audioBuffer->channels = sample->actual.channels;

		switch (sample->actual.format)
		{
			case AUDIO_U8:
			case AUDIO_S8:
				audioBuffer->bitsPerSample = 8;
				break;

			case AUDIO_F32LSB:
			case AUDIO_F32MSB:
				audioBuffer->bitsPerSample = 32;
				break;

			case AUDIO_U16LSB:
			case AUDIO_S16LSB:
			case AUDIO_U16MSB:
			case AUDIO_S16MSB:
			default:
				audioBuffer->bitsPerSample = 16;
				break;
		}

		// TODO: Add support for streaming sound in higher APIs
		// TODO: This seems a few bits short?
		Uint32 dataLength = (Sound_GetDuration (sample) * audioBuffer->sampleRate * audioBuffer->channels * (audioBuffer->bitsPerSample / 8)) / 1000;

		// audioBuffer->data->Resize (dataLength);
		// unsigned char* bytes = audioBuffer->data->buffer->b;
		unsigned char* bytes = NULL;

		Uint32 bytesWritten = 0;
		Uint32 decodedBytes = 0;
		Uint8* decodedPtr = NULL;

		while (bytesWritten < dataLength) {

			if (((sample->flags & SOUND_SAMPLEFLAG_ERROR) == 0) && ((sample->flags & SOUND_SAMPLEFLAG_EOF) == 0)) {

                decodedBytes = Sound_Decode(sample);
                decodedPtr = (unsigned char*)sample->buffer;

            }

            if (decodedBytes == 0)
            {
                // memset(bytes + bytesWritten, '\0', dataLength - bytesWritten);  /* write silence. */
                break;
            }
			else
			{
				Uint32 copySize = decodedBytes;
				// int copySize = dataLength - bytesWritten;
				// if (copySize > decodedBytes) copySize = decodedBytes;

				audioBuffer->data->Resize (bytesWritten + copySize);
				bytes = audioBuffer->data->buffer->b;

				memcpy(bytes + bytesWritten, decodedPtr, copySize);

				bytesWritten += copySize;
				decodedPtr += copySize;
				decodedBytes -= copySize;
			}

		}

		Sound_FreeSample(sample);
		return true;

	}


}