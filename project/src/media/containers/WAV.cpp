#include <media/containers/WAV.h>
#include <system/System.h>


namespace lime {


	template<typename T>
	inline const char* readStruct (T& dest, const char*& ptr) {

		const char* ret;
		memcpy (&dest, ptr, sizeof (T));
		ptr += sizeof (WAVE_Data);
		ret = ptr;
		ptr += dest.subChunkSize;
		return ret;

	}


	const char* find_chunk (const char* start, const char* end, const char* chunkID) {

		WAVE_Data chunk;
		const char* ptr = start;

		while (ptr < (end - sizeof(WAVE_Data))) {

			memcpy (&chunk, ptr, sizeof (WAVE_Data));

			if (chunk.subChunkID[0] == chunkID[0] && chunk.subChunkID[1] == chunkID[1] && chunk.subChunkID[2] == chunkID[2] && chunk.subChunkID[3] == chunkID[3]) {

				return ptr;

			}

			ptr += sizeof (WAVE_Data) + chunk.subChunkSize;

		}

		return 0;

	}


	bool WAV::Decode (Resource *resource, AudioBuffer *audioBuffer) {

		WAVE_Format wave_format;
		RIFF_Header riff_header;
		WAVE_Data wave_data;
		unsigned char* data;

		FILE_HANDLE *file = NULL;

		if (resource->path) {

			file = lime::fopen (resource->path, "rb");

			if (!file) {

				return false;

			}

			int result = lime::fread (&riff_header, sizeof (RIFF_Header), 1, file);

			if ((riff_header.chunkID[0] != 'R' || riff_header.chunkID[1] != 'I' || riff_header.chunkID[2] != 'F' || riff_header.chunkID[3] != 'F') || (riff_header.format[0] != 'W' || riff_header.format[1] != 'A' || riff_header.format[2] != 'V' || riff_header.format[3] != 'E')) {

				lime::fclose (file);
				return false;

			}

			long int currentHead = 0;
			bool foundFormat = false;

			while (!foundFormat) {

				currentHead = lime::ftell (file);
				result = lime::fread (&wave_format, sizeof (WAVE_Format), 1, file);

				if (result != 1) {

					LOG_SOUND ("Invalid Wave Format!\n");
					lime::fclose (file);
					return false;

				}

				if (wave_format.subChunkID[0] != 'f' || wave_format.subChunkID[1] != 'm' || wave_format.subChunkID[2] != 't' || wave_format.subChunkID[3] != ' ') {

					lime::fseek (file, currentHead + sizeof (WAVE_Data) + wave_format.subChunkSize, SEEK_SET);

				} else {

					foundFormat = true;

				}

			}

			bool foundData = false;

			while (!foundData) {

				currentHead = lime::ftell (file);
				result = lime::fread (&wave_data, sizeof (WAVE_Data), 1, file);

				if (result != 1) {

					LOG_SOUND ("Invalid Wav Data Header!\n");
					lime::fclose (file);
					return false;

				}

				if (wave_data.subChunkID[0] != 'd' || wave_data.subChunkID[1] != 'a' || wave_data.subChunkID[2] != 't' || wave_data.subChunkID[3] != 'a') {

					lime::fseek (file, currentHead + sizeof (WAVE_Data) + wave_data.subChunkSize, SEEK_SET);

				} else {

					foundData = true;

				}

			}

			audioBuffer->data->Resize (wave_data.subChunkSize);

			if (!lime::fread (audioBuffer->data->buffer->b, wave_data.subChunkSize, 1, file)) {

				LOG_SOUND ("error loading WAVE data into struct!\n");
				lime::fclose (file);
				return false;

			}

			lime::fclose (file);

		} else {

			const char* start = (const char*)resource->data->b;
			const char* end = start + resource->data->length;
			const char* ptr = start;

			memcpy (&riff_header, ptr, sizeof (RIFF_Header));
			ptr += sizeof (RIFF_Header);

			if ((riff_header.chunkID[0] != 'R' || riff_header.chunkID[1] != 'I' || riff_header.chunkID[2] != 'F' || riff_header.chunkID[3] != 'F') || (riff_header.format[0] != 'W' || riff_header.format[1] != 'A' || riff_header.format[2] != 'V' || riff_header.format[3] != 'E')) {

				return false;

			}

			ptr = find_chunk (ptr, end, "fmt ");

			if (!ptr) {

				return false;

			}

			readStruct (wave_format, ptr);

			if (wave_format.subChunkID[0] != 'f' || wave_format.subChunkID[1] != 'm' || wave_format.subChunkID[2] != 't' || wave_format.subChunkID[3] != ' ') {

				LOG_SOUND ("Invalid Wave Format!\n");
				return false;

			}

			ptr = find_chunk (ptr, end, "data");

			if (!ptr) {

				return false;

			}

			const char* base = readStruct (wave_data, ptr);

			if (wave_data.subChunkID[0] != 'd' || wave_data.subChunkID[1] != 'a' || wave_data.subChunkID[2] != 't' || wave_data.subChunkID[3] != 'a') {

				LOG_SOUND ("Invalid Wav Data Header!\n");
				return false;

			}

			audioBuffer->data->Resize (wave_data.subChunkSize);

			size_t size = wave_data.subChunkSize;

			if (size > (end - base)) {

				return false;

			}

			unsigned char* bytes = audioBuffer->data->buffer->b;
			memcpy (bytes, base, size);

		}

		audioBuffer->sampleRate = (int)wave_format.sampleRate;
		audioBuffer->channels = wave_format.numChannels;
		audioBuffer->bitsPerSample = wave_format.bitsPerSample;

		return true;

	}


}