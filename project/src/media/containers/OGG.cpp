#include <media/codecs/vorbis/VorbisFile.h>
#include <media/containers/OGG.h>
#include <system/System.h>
#include <limits.h>
#include <string.h>


namespace lime {


	static bool DecodeOGG (Resource *resource, AudioBuffer *audioBuffer);


	bool OGG::Decode (Resource *resource, AudioBuffer *audioBuffer) {

		// libvorbis only reads the encoded sound and writes the buffer's own
		// memory, so the collector needn't wait for this thread: a decode on a
		// worker thread otherwise holds up every collection until it finishes
		System::GCEnterBlocking ();
		bool decoded = DecodeOGG (resource, audioBuffer);
		System::GCExitBlocking ();

		return decoded;

	}


	static bool DecodeOGG (Resource *resource, AudioBuffer *audioBuffer) {

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

		// The length the file gives only sizes the buffer to start with: it is
		// an error code for some streams, can be too long for an int, and in a
		// damaged file can be shorter than the audio. So the buffer grows as
		// the audio comes, and no read goes past its end.
		int frameSize = audioBuffer->channels * audioBuffer->bitsPerSample / 8;
		ogg_int64_t frames = ov_pcm_total (oggFile, -1);
		int capacity = BUFFER_SIZE;

		if (frames > 0 && frameSize > 0 && frames <= (ogg_int64_t)(INT_MAX / frameSize)) {

			capacity = (int)(frames * frameSize);

		}

		bool failed = !audioBuffer->data->TryResize (capacity);
		char extra[BUFFER_SIZE];

		while (!failed) {

			// Near the end of the buffer, a block is read aside: ov_read gives
			// nothing when asked for less than a sample frame
			int room = capacity - totalBytes;
			bool direct = room >= BUFFER_SIZE;
			char* target = direct ? (char*)audioBuffer->data->buffer->b + totalBytes : extra;
			bytes = ov_read (oggFile, target, BUFFER_SIZE, BUFFER_READ_TYPE, 2, 1, &bitStream);

			if (bytes <= 0) {

				break;

			}

			if (!direct) {

				if (bytes > room) {

					// More audio than the file said: grow by half, as far as an int goes
					if (bytes > INT_MAX - totalBytes) {

						failed = true;
						break;

					}

					ogg_int64_t needed = (ogg_int64_t)totalBytes + bytes;
					ogg_int64_t grown = (ogg_int64_t)capacity + capacity / 2;
					if (grown < needed) grown = needed;
					if (grown > INT_MAX) grown = INT_MAX;

					if (!audioBuffer->data->TryResize ((int)grown)) {

						failed = true;
						break;

					}

					capacity = (int)grown;

				}

				memcpy ((char*)audioBuffer->data->buffer->b + totalBytes, extra, bytes);

			}

			totalBytes += bytes;

		}

		if (failed) {

			audioBuffer->data->Resize (0);
			ov_clear (oggFile);
			delete oggFile;

			return false;

		}

		if (capacity != totalBytes) {

			audioBuffer->data->Resize (totalBytes);

		}

		ov_clear (oggFile);
		delete oggFile;

		#undef BUFFER_READ_TYPE

		return true;

	}


}