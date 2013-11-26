#ifndef AUDIO_H
#define AUDIO_H

#include <QuickVec.h>
#include <Sound.h>
#include <Utils.h>

#ifdef ANDROID
#include <android/log.h>
#endif


#ifdef ANDROID
#define LOG_SOUND(args,...) ELOG(args, ##__VA_ARGS__)
#else
#ifdef IPHONE
//#define LOG_SOUND(args,...) printf(args, ##__VA_ARGS__)
#define LOG_SOUND(args...) { }
#else
#define LOG_SOUND(args,...) printf(args, ##__VA_ARGS__)
#endif
#endif
//#define LOG_SOUND(args...)  { }


namespace nme
{
	class AudioSample
	{
	};
	
	class AudioStream
	{
	public:
		virtual ~AudioStream() {}
		
		virtual void release() = 0;
		virtual bool playback() = 0;
        virtual bool playing() = 0;
		virtual bool update() = 0;
		
		virtual void setTransform(const SoundTransform &inTransform) = 0;
		virtual double getPosition() = 0;
		virtual double setPosition(const float &inFloat) = 0;
		virtual double getLeft() = 0;
		virtual double getRight() = 0;
		
		virtual void suspend() = 0;
		virtual void resume() = 0;
		
		virtual bool isActive() = 0;
		
	};
	
	enum AudioFormat
	{
		eAF_unknown,
		eAF_auto,
		eAF_ogg,
		eAF_wav,
		eAF_mp3,
		eAF_count
	};
	
	namespace Audio
	{
		AudioFormat determineFormatFromBytes(const float *inData, int len);
		AudioFormat determineFormatFromFile(const std::string &filename);
		
		bool loadOggSampleFromBytes(const float *inData, int len, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate);
		bool loadOggSampleFromFile(const char *inFileURL, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate);
		
		bool loadWavSampleFromBytes(const float *inData, int len, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate);
		bool loadWavSampleFromFile(const char *inFileURL, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate);
	}
	
	struct RIFF_Header
	{
		char chunkID[4];
		unsigned int chunkSize; //size not including chunkSize or chunkID
		char format[4];
	};
	
	struct WAVE_Format
	{
		char subChunkID[4];
		unsigned int subChunkSize;
		short audioFormat;
		short numChannels;
		unsigned int sampleRate;
		unsigned int byteRate;
		short blockAlign;
		short bitsPerSample;
	};
	
	struct WAVE_Data
	{
		char subChunkID[4]; //should contain the word data
		unsigned int subChunkSize; //Stores the size of the data block
	};

}

#endif