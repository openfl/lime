#ifndef LIME_MEDIA_CONTAINERS_WAV_H
#define LIME_MEDIA_CONTAINERS_WAV_H


#include <media/AudioBuffer.h>
#include <utils/Resource.h>


namespace lime {


	struct RIFF_Header {

		char chunkID[4];
		unsigned int chunkSize; //size not including chunkSize or chunkID
		char format[4];

	};


	struct WAVE_Format {

		char subChunkID[4];
		unsigned int subChunkSize;
		short audioFormat;
		short numChannels;
		unsigned int sampleRate;
		unsigned int byteRate;
		short blockAlign;
		short bitsPerSample;

	};


	struct WAVE_Data {

		char subChunkID[4]; //should contain the word data
		unsigned int subChunkSize; //Stores the size of the data block

	};


	class WAV {


		public:

			static bool Decode (Resource *resource, AudioBuffer *audioBuffer);


	};


}


#endif