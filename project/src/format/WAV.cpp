#include <format/WAV.h>


namespace lime {
	
	
	bool WAV::Decode (Resource *resource, Sound *sound) {
		
		WAVE_Format wave_format;
		RIFF_Header riff_header;
		WAVE_Data wave_data;
		unsigned char* data;
		
		FILE *f = NULL;
		
		if (resource->path) {
		
		
		//http://www.dunsanyinteractive.com/blogs/oliver/?p=72
			
			//Local Declarations
			
			
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
			
			long int currentHead = 0;
			bool foundFormat = false;
			while (!foundFormat)
			{
				// Save the current position indicator of the stream
				currentHead = ftell(f);
				
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
					//fseek(f, wave_data.subChunkSize, SEEK_CUR);
					//fseek(f, wave_data.subChunkSize, SEEK_CUR);
					// Goto next chunk.
					fseek(f, currentHead + sizeof(WAVE_Data) + wave_format.subChunkSize, SEEK_SET);
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
			
		} else {
			
			const char* start = resource->data->Bytes ();
			const char* end = start + resource->data->Size ();
			const char* ptr = start;
			
			// Read in the first chunk into the struct
			memcpy (&riff_header, ptr, sizeof (RIFF_Header));
			ptr += sizeof (RIFF_Header);
			
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
		
		
	}
	
	
}