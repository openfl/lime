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
	
	
	struct HL_AudioBuffer {
		
		hl_type* t;
		int bitsPerSample;
		int channels;
		HL_ArrayBufferView* data;
		int sampleRate;
		
		vdynamic* __srcAudio;
		vdynamic* __srcBuffer;
		vdynamic* __srcCustom;
		vdynamic* __srcFMODSound;
		vdynamic* __srcHowl;
		vdynamic* __srcSound;
		vdynamic* __srcVorbisFile;
		
	};
	
	
	class AudioBuffer {
		
		
		public:
			
			AudioBuffer ();
			AudioBuffer (value audioBuffer);
			AudioBuffer (HL_AudioBuffer* audioBuffer);
			~AudioBuffer ();
			
			void* Value ();
			
			int bitsPerSample;
			int channels;
			int sampleRate;
			ArrayBufferView *data;
			
		private:
			
			HL_AudioBuffer* _buffer;
			value _value;
		
		
	};
	
	
}


#endif