#ifndef LIME_MEDIA_AUDIO_BUFFER_H
#define LIME_MEDIA_AUDIO_BUFFER_H


#include <system/CFFI.h>
#include <utils/ArrayBufferView.h>

#ifdef ANDROID
#include <android/log.h>
#endif


#ifdef ANDROID
#define LOG_SOUND(args,...) __android_log_print(ANDROID_LOG_INFO, "Lime", args, ##__VA_ARGS__)
#else
#ifdef IPHONE
//#define LOG_SOUND(args,...) printf(args, ##__VA_ARGS__)
#define LOG_SOUND(args...) { }
#elif defined(TIZEN)
#include <FBase.h>
#define LOG_SOUND(args,...) AppLog(args, ##__VA_ARGS__)
#else
#define LOG_SOUND(args,...) printf(args, ##__VA_ARGS__)
#endif
#endif
//#define LOG_SOUND(args...)  { }


namespace lime {


	struct AudioBuffer {

		hl_type* t;
		int bitsPerSample;
		int channels;
		ArrayBufferView* data;
		int sampleRate;

		vdynamic* __srcAudio;
		vdynamic* __srcBuffer;
		vdynamic* __srcCustom;
		vdynamic* __srcHowl;
		vdynamic* __srcSound;
		vdynamic* __srcVorbisFile;

		AudioBuffer (value audioBuffer);
		~AudioBuffer ();
		value Value (value audioBuffer);
		value Value ();

	};


}


#endif