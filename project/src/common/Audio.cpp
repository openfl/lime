#include <Audio.h>

#include <ByteArray.h>
#include <cstdio>
#include <iostream>
#include <vorbis/vorbisfile.h>

//The audio interface is to embed functions which are to be implemented in 
//the platform specific layers. 

namespace lime
{
	namespace Audio
	{
		
		typedef struct
		{
			unsigned char* data;
			ogg_int64_t size;
			ogg_int64_t pos;
		} OAL_OggMemoryFile;
		
		
		static size_t OAL_OggBufferRead(void* dest, size_t eltSize, size_t nelts, OAL_OggMemoryFile* src)
		{
			size_t len = eltSize * nelts;
			if ( (src->pos + len) > src->size)
			{
				len = src->size - src->pos;
			}
			if (len > 0)
			{
				memcpy( dest, (src->data + src->pos), len);
				src->pos += len;
			}
			return len;
		}
		
		
		static int OAL_OggBufferSeek(OAL_OggMemoryFile* src, ogg_int64_t pos, int whence)
		{
			switch (whence) {
				case SEEK_CUR:
					src->pos += pos;
					break;
				case SEEK_END:
					src->pos = src->size - pos;
					break;
				case SEEK_SET:
					src->pos = pos;
					break;
				default:
					return -1;
			}
			if (src->pos < 0) {
				src->pos = 0;
				return -1;
			}
			if (src->pos > src->size) {
				return -1;
			}
			return 0;
		}
		
		
		static int OAL_OggBufferClose(OAL_OggMemoryFile* src)
		{
			return 0;
		}
		
		
		static long OAL_OggBufferTell(OAL_OggMemoryFile *src)
		{
			return src->pos;
		}
		
		
		static ov_callbacks OAL_CALLBACKS_BUFFER = {
			(size_t (*)(void *, size_t, size_t, void *))	OAL_OggBufferRead,
			(int (*)(void *, ogg_int64_t, int))				OAL_OggBufferSeek,
			(int (*)(void *))								OAL_OggBufferClose,
			(long (*)(void *))								OAL_OggBufferTell
		};
		
		
		template<typename T>
		inline const char*readStruct(T& dest, const char*& ptr)
		{
			const char* ret;
			memcpy(&dest, ptr, sizeof(T));
			ptr += sizeof(WAVE_Data);
			ret = ptr;
			ptr += dest.subChunkSize;
			return ret;
		}
		
		
		const char* find_chunk(const char* start, const char* end, const char* chunkID)
		{
			WAVE_Data chunk;
			const char* ptr = start;
			while (ptr < (end - sizeof(WAVE_Data)))
			{
				memcpy(&chunk, ptr, sizeof(WAVE_Data));

				if (chunk.subChunkID[0] == chunkID[0] &&
					chunk.subChunkID[1] == chunkID[1] &&
					chunk.subChunkID[2] == chunkID[2] &&
					chunk.subChunkID[3] == chunkID[3])
				{
					return ptr;
				}
				ptr += sizeof(WAVE_Data) + chunk.subChunkSize;
			}
			return 0;
		}
		
		
		bool CompareBuffer(const char* apBuffer, const char* asMatch, size_t aSize)
		{
			for (int p= 0; p < aSize; ++p)
			{
				if (apBuffer[p] != asMatch[p]) return false;
			}
			return true;
		}
		
		
		std::string _get_extension(const std::string& _filename)
		{
			if(_filename.find_last_of(".") != std::string::npos)
				return _filename.substr(_filename.find_last_of(".") + 1);
			return "";
		}
		
		
		AudioFormat determineFormatFromBytes(const float *inData, int len)
		{
			const char* buff = (char*)inData;
			if (len >= 35 && CompareBuffer(buff, "OggS", 4) && CompareBuffer(&buff[28], "\x01vorbis", 7))
			{
				return eAF_ogg;
			}
			if (len >= 12 && CompareBuffer(buff, "RIFF", 4) && CompareBuffer(&buff[8], "WAVE", 4))
			{
				return eAF_wav;
			}
			return eAF_unknown;
		}
		
		
		AudioFormat determineFormatFromFile(const std::string &filename)
		{
			std::string extension = _get_extension(filename);
			
			if( extension.compare("ogg") == 0 || extension.compare("oga") == 0)
				return eAF_ogg;
			else if( extension.compare("wav") == 0)
				return eAF_wav;
			else if (extension.compare("mp3") == 0)
				return eAF_mp3;
			
			AudioFormat format = eAF_unknown;
			
			#ifdef ANDROID
			FileInfo info = AndroidGetAssetFD(filename.c_str());
			FILE *f = fdopen(info.fd, "rb");
			fseek(f, info.offset, 0);
			#else
			FILE *f = fopen(filename.c_str(), "rb");
			#endif
			
			int len = 35;
			char *bytes = (char*)calloc(len + 1, sizeof(char));
			
			if (f)
			{
				if (fread(bytes, 1, len, f))
				{
					fclose(f);
					format = determineFormatFromBytes((float*)bytes, len);
				}
				
				fclose(f);
			}
			
			delete bytes;
			return format;
		}
		
		
		bool loadOggSample(OggVorbis_File &oggFile, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate)
		{
			// 0 for Little-Endian, 1 for Big-Endian
			#ifdef HXCPP_BIG_ENDIAN
			#define BUFFER_READ_TYPE 1
			#else
			#define BUFFER_READ_TYPE 0
			#endif
			
			int bitStream;
			long bytes = 1;
			int totalBytes = 0;
			
			#define BUFFER_SIZE 32768
			
			//Get the file information
			//vorbis data
			vorbis_info *pInfo = ov_info(&oggFile, -1);            
			//Make sure this is a valid file
			if (pInfo == NULL)
			{
				LOG_SOUND("FAILED TO READ OGG SOUND INFO, IS THIS EVEN AN OGG FILE?\n");
				return false;
			}
			
			//The number of channels
			*channels = pInfo->channels;
			//default to 16? todo 
			*bitsPerSample = 16;
			//Return the same rate as well
			*outSampleRate = pInfo->rate;
			
			// Seem to need four times the read PCM total
			outBuffer.resize(ov_pcm_total(&oggFile, -1)*4);
			
			while (bytes > 0)
			{
				if (outBuffer.size() < totalBytes + BUFFER_SIZE)
				{
					outBuffer.resize(totalBytes + BUFFER_SIZE);
				}
				// Read up to a buffer's worth of decoded sound data
				bytes = ov_read(&oggFile, (char*)outBuffer.begin() + totalBytes, BUFFER_SIZE, BUFFER_READ_TYPE, 2, 1, &bitStream);
				totalBytes += bytes;
			}
			
			outBuffer.resize(totalBytes);
			ov_clear(&oggFile);
			
			#undef BUFFER_SIZE
			#undef BUFFER_READ_TYPE
			
			return true;
		}
		
		
		bool loadOggSampleFromBytes(const float *inData, int len, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate)
		{
			OAL_OggMemoryFile fakeFile = { (unsigned char*)inData, len, 0 };
			OggVorbis_File ovFileHandle;
			
			if (ov_open_callbacks(&fakeFile, &ovFileHandle, NULL, 0, OAL_CALLBACKS_BUFFER) == 0)
			{
				return loadOggSample(ovFileHandle, outBuffer, channels, bitsPerSample, outSampleRate);
			}
			
			return false;
		}
		
		
		bool loadOggSampleFromFile(const char *inFileURL, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate)
		{
			FILE *f;
			
			//Read the file data
			#ifdef ANDROID
			FileInfo info = AndroidGetAssetFD(inFileURL);
			f = fdopen(info.fd, "rb");
			fseek(f, info.offset, 0);
			#else
			f = fopen(inFileURL, "rb");
			#endif
			
			if (!f)
			{
				LOG_SOUND("FAILED to read sound file, file pointer as null?\n");
				return false;
			}
			
			OggVorbis_File oggFile;
			//Read the file data
			#ifdef ANDROID
			ov_open(f, &oggFile, NULL, info.length);
			#else
			ov_open(f, &oggFile, NULL, 0);
			#endif
			
			return loadOggSample(oggFile, outBuffer, channels, bitsPerSample, outSampleRate);
		}
		
		
		bool loadWavSampleFromBytes(const float *inData, int len, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate)
		{
			const char* start = (const char*)inData;
			const char* end = start + len;
			const char* ptr = start;
			WAVE_Format wave_format;
			RIFF_Header riff_header;
			WAVE_Data wave_data;
			unsigned char* data;
			
			// Read in the first chunk into the struct
			memcpy(&riff_header, ptr, sizeof(RIFF_Header));
			ptr += sizeof(RIFF_Header);
			
			//check for RIFF and WAVE tag in memeory
			if ((riff_header.chunkID[0] != 'R'  ||
				riff_header.chunkID[1] != 'I'  ||
				riff_header.chunkID[2] != 'F'  ||
				riff_header.chunkID[3] != 'F') ||
				(riff_header.format[0] != 'W'  ||
				riff_header.format[1] != 'A'  ||
				riff_header.format[2] != 'V'  ||
				riff_header.format[3] != 'E'))
			{
				LOG_SOUND("Invalid RIFF or WAVE Header!\n");
				return false;
			}
			
			//Read in the 2nd chunk for the wave info
			ptr = find_chunk(ptr, end, "fmt ");
			if (!ptr) {
				return false;
			}
			readStruct(wave_format, ptr);
			
			//check for fmt tag in memory
			if (wave_format.subChunkID[0] != 'f' ||
				wave_format.subChunkID[1] != 'm' ||
				wave_format.subChunkID[2] != 't' ||
				wave_format.subChunkID[3] != ' ') 
			{
				LOG_SOUND("Invalid Wave Format!\n");
				return false;
			}
			
			ptr = find_chunk(ptr, end, "data");
			if (!ptr) {
				return false;
			}
			
			const char* base = readStruct(wave_data, ptr);
			
			//check for data tag in memory
			if (wave_data.subChunkID[0] != 'd' ||
				wave_data.subChunkID[1] != 'a' ||
				wave_data.subChunkID[2] != 't' ||
				wave_data.subChunkID[3] != 'a')
			{
				LOG_SOUND("Invalid Wav Data Header!\n");
				return false;
			}
			
			//Allocate memory for data
			//data = new unsigned char[wave_data.subChunk2Size];
			
			// Read in the sound data into the soundData variable
			size_t size = wave_data.subChunkSize;
			if (size > (end - base)) {
				return false;
			}
			
			/*mlChannels = wave_format.numChannels;
			if (mlChannels == 2)
			{
				if (wave_format.bitsPerSample == 8)
				{
					mFormat = AL_FORMAT_STEREO8;
					mlSamples = size / 2;
				}
				else //if (wave_format.bitsPerSample == 16)
				{
					mlSamples = size / 4;
					mFormat = AL_FORMAT_STEREO16;
				}
			} else //if (mlChannels == 1)
			{
				if (wave_format.bitsPerSample == 8)
				{
					mlSamples = size;
					mFormat = AL_FORMAT_MONO8;
				}
				else //if (wave_format.bitsPerSample == 16)
				{
					mlSamples = size / 2;
					mFormat = AL_FORMAT_MONO16;
				}
			}
			mlFrequency = wave_format.sampleRate;
			mfTotalTime = float(mlSamples) / float(mlFrequency);*/
			
			//Store in the outbuffer
			outBuffer.Set((unsigned char*)base, size);
			
			//Now we set the variables that we passed in with the
			//data from the structs
			*outSampleRate = (int)wave_format.sampleRate;
			
			//The format is worked out by looking at the number of
			//channels and the bits per sample.
			*channels = wave_format.numChannels;
			*bitsPerSample = wave_format.bitsPerSample;
			
			//clean up and return true if successful
			//fclose(f);
			//delete[] data;
			
			return true;
		}
		
		
		bool loadWavSampleFromFile(const char *inFileURL, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate)
		{
			//http://www.dunsanyinteractive.com/blogs/oliver/?p=72
			
			//Local Declarations
			FILE* f = NULL;
			WAVE_Format wave_format;
			RIFF_Header riff_header;
			WAVE_Data wave_data;
			unsigned char* data;
			
			#ifdef ANDROID
			FileInfo info = AndroidGetAssetFD(inFileURL);
			f = fdopen(info.fd, "rb");
			fseek(f, info.offset, 0);
			#else
			f = fopen(inFileURL, "rb");
			#endif
			
			if (!f)
			{
				LOG_SOUND("FAILED to read sound file, file pointer as null?\n");
				return false;
			}
			
			// Read in the first chunk into the struct
			int result = fread(&riff_header, sizeof(RIFF_Header), 1, f);
			//check for RIFF and WAVE tag in memeory
			if ((riff_header.chunkID[0] != 'R'  ||
				riff_header.chunkID[1] != 'I'  ||
				riff_header.chunkID[2] != 'F'  ||
				riff_header.chunkID[3] != 'F') ||
				(riff_header.format[0] != 'W'  ||
				riff_header.format[1] != 'A'  ||
				riff_header.format[2] != 'V'  ||
				riff_header.format[3] != 'E'))
			{
				LOG_SOUND("Invalid RIFF or WAVE Header!\n");
				return false;
			}
			
			bool foundFormat = false;
			while (!foundFormat)
			{
				//Read in the 2nd chunk for the wave info
				result = fread(&wave_format, sizeof(WAVE_Format), 1, f);
				
				if (result != 1)
				{
					LOG_SOUND("Invalid Wave Format!\n");
					return false;
				}
				
				//check for fmt tag in memory
				if (wave_format.subChunkID[0] != 'f' ||
					wave_format.subChunkID[1] != 'm' ||
					wave_format.subChunkID[2] != 't' ||
					wave_format.subChunkID[3] != ' ') 
				{
					fseek(f, wave_data.subChunkSize, SEEK_CUR);
				}
				else
				{
					foundFormat = true;
				}
			}
			
			//check for extra parameters;
			if (wave_format.subChunkSize > 16)
			{
				fseek(f, sizeof(short), SEEK_CUR);
			}
			
			bool foundData = false;
			while (!foundData)
			{
				//Read in the the last byte of data before the sound file
				result = fread(&wave_data, sizeof(WAVE_Data), 1, f);
				
				if (result != 1)
				{
					LOG_SOUND("Invalid Wav Data Header!\n");
					return false;
				}
				
				if (wave_data.subChunkID[0] != 'd' ||
				wave_data.subChunkID[1] != 'a' ||
				wave_data.subChunkID[2] != 't' ||
				wave_data.subChunkID[3] != 'a')
				{
					fseek(f, wave_data.subChunkSize, SEEK_CUR);
				}
				else
				{
					foundData = true;
				}
			}
			
			//Allocate memory for data
			data = new unsigned char[wave_data.subChunkSize];
			
			// Read in the sound data into the soundData variable
			if (!fread(data, wave_data.subChunkSize, 1, f))
			{
				LOG_SOUND("error loading WAVE data into struct!\n");
				return false;
			}   
			
			//Store in the outbuffer
			outBuffer.Set(data, wave_data.subChunkSize);
			
			//Now we set the variables that we passed in with the
			//data from the structs
			*outSampleRate = (int)wave_format.sampleRate;
			
			//The format is worked out by looking at the number of
			//channels and the bits per sample.
			*channels = wave_format.numChannels;
			*bitsPerSample = wave_format.bitsPerSample;
			
			//clean up and return true if successful
			fclose(f);
			delete[] data;
			
			return true;
		}
		
		
	}
}
