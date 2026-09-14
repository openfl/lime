#ifndef LIME_MEDIA_DECODERS_SDL_SOUND_H
#define LIME_MEDIA_DECODERS_SDL_SOUND_H


#include "SDL_sound.h"
#include <media/AudioBuffer.h>
#include <utils/Resource.h>


namespace lime {


	struct SDLSoundStreamInfo {

		int bitsPerSample;
		bool canSeek;
		int channels;
		int duration;
		int sampleRate;

		SDLSoundStreamInfo () : bitsPerSample (0), canSeek (false), channels (0), duration (0), sampleRate (0) {}

	};


	struct SDLSoundStream {

		Sound_Sample* sample;

		SDLSoundStream () : sample (NULL) {}

	};


	class SDLSound {


		public:

			static bool Decode (Resource *resource, AudioBuffer *audioBuffer);
			static bool GetStreamInfo (Resource *resource, SDLSoundStreamInfo *streamInfo);
			static SDLSoundStream* OpenStream (Resource *resource);
			static int ReadStream (SDLSoundStream *stream, unsigned char *buffer, int length);
			static bool RewindStream (SDLSoundStream *stream);
			static bool SeekStream (SDLSoundStream *stream, int ms);
			static void CloseStream (SDLSoundStream *stream);


	};


}


#endif
