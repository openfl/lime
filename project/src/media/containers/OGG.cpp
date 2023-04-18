#include <media/codecs/vorbis/VorbisFile.h>
#include <media/containers/OGG.h>


namespace lime {


	bool OGG::Decode (Resource *resource, AudioBuffer *audioBuffer) {

		OggVorbis_File* oggFile;
		Bytes *data = NULL;

		if (resource->path) {

			oggFile = VorbisFile::FromFile (resource->path);

		} else {

			oggFile = VorbisFile::FromBytes (resource->data);

		}

		if (!oggFile) {

			return false;

		}

		// 0 for Little-Endian, 1 for Big-Endian
		#ifdef HXCPP_BIG_ENDIAN
		#define BUFFER_READ_TYPE 1
		#else
		#define BUFFER_READ_TYPE 0
		#endif

		int bitStream;
		long bytes = 1;
		int totalBytes = 0;

		#define BUFFER_SIZE 4096

		vorbis_info *pInfo = ov_info (oggFile, -1);

		if (pInfo == NULL) {

			//LOG_SOUND("FAILED TO READ OGG SOUND INFO, IS THIS EVEN AN OGG FILE?\n");
			ov_clear (oggFile);
			delete oggFile;

			return false;

		}

		audioBuffer->channels = pInfo->channels;
		audioBuffer->sampleRate = pInfo->rate;

		audioBuffer->bitsPerSample = 16;

		int dataLength = ov_pcm_total (oggFile, -1) * audioBuffer->channels * audioBuffer->bitsPerSample / 8;
		audioBuffer->data->Resize (dataLength);

		while (bytes > 0) {

			bytes = ov_read (oggFile, (char *)audioBuffer->data->buffer->b + totalBytes, BUFFER_SIZE, BUFFER_READ_TYPE, 2, 1, &bitStream);

			if (bytes > 0) {

				totalBytes += bytes;

			}

		}

		if (dataLength != totalBytes) {

			audioBuffer->data->Resize (totalBytes);

		}

		ov_clear (oggFile);
		delete oggFile;

		#undef BUFFER_READ_TYPE

		return true;

	}


}