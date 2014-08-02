#include <audio/format/OGG.h>
#include <utils/FileIO.h>
#include <vorbis/vorbisfile.h>


namespace lime {
	
	
	typedef struct {
		
		unsigned char* data;
		ogg_int64_t size;
		ogg_int64_t pos;
		
	} OAL_OggMemoryFile;
	
	
	static size_t OAL_OggBufferRead (void* dest, size_t eltSize, size_t nelts, OAL_OggMemoryFile* src) {
		
		size_t len = eltSize * nelts;
		
		if ((src->pos + len) > src->size) {
			
			len = src->size - src->pos;
			
		}
		
		if (len > 0) {
			
			memcpy (dest, (src->data + src->pos), len);
			src->pos += len;
			
		}
		
		return len;
		
	}
	
	
	static int OAL_OggBufferSeek (OAL_OggMemoryFile* src, ogg_int64_t pos, int whence) {
		
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
	
	
	static int OAL_OggBufferClose (OAL_OggMemoryFile* src) {
		
		return 0;
		
	}
	
	
	static long OAL_OggBufferTell (OAL_OggMemoryFile *src) {
		
		return src->pos;
		
	}
	
	
	static ov_callbacks OAL_CALLBACKS_BUFFER = {
		
		(size_t (*)(void *, size_t, size_t, void *)) OAL_OggBufferRead,
		(int (*)(void *, ogg_int64_t, int)) OAL_OggBufferSeek,
		(int (*)(void *)) OAL_OggBufferClose,
		(long (*)(void *)) OAL_OggBufferTell
		
	};
	
	
	bool OGG::Decode (Resource *resource, AudioBuffer *audioBuffer) {
		
		OggVorbis_File oggFile;
		
		if (resource->path) {
			
			FILE *file;
			
			#ifdef ANDROID
			FileInfo info = AndroidGetAssetFD (resource->path);
			file = lime::fdopen (info.fd, "rb");
			lime::fseek (file, info.offset, 0);
			#else
			file = lime::fopen (resource->path, "rb");
			#endif
			
			if (!file) {
				
				//LOG_SOUND("FAILED to read audio file, file pointer as null?\n");
				return false;
				
			}
			
			#ifdef ANDROID
			ov_open (file, &oggFile, NULL, info.length);
			#else
			ov_open (file, &oggFile, NULL, 0);
			#endif
			
		} else {
			
			OAL_OggMemoryFile fakeFile = { resource->data->Bytes (), resource->data->Size (), 0 };
			
			if (ov_open_callbacks (&fakeFile, &oggFile, NULL, 0, OAL_CALLBACKS_BUFFER) != 0) {
				
				return false;
				
			}
			
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
		
		#define BUFFER_SIZE 32768
		
		vorbis_info *pInfo = ov_info (&oggFile, -1);            
		
		if (pInfo == NULL) {
			
			//LOG_SOUND("FAILED TO READ OGG SOUND INFO, IS THIS EVEN AN OGG FILE?\n");
			return false;
			
		}
		
		audioBuffer->channels = pInfo->channels;
		audioBuffer->sampleRate = pInfo->rate;
		
		//default to 16? todo 
		audioBuffer->bitsPerSample = 16;
		
		// Seem to need four times the read PCM total
		audioBuffer->data->Resize (ov_pcm_total (&oggFile, -1) * 4);
		
		while (bytes > 0) {
			
			if (audioBuffer->data->Size () < totalBytes + BUFFER_SIZE) {
				
				audioBuffer->data->Resize (totalBytes + BUFFER_SIZE);
				
			}
			
			bytes = ov_read (&oggFile, (char *)audioBuffer->data->Bytes () + totalBytes, BUFFER_SIZE, BUFFER_READ_TYPE, 2, 1, &bitStream);
			totalBytes += bytes;
			
		}
		
		audioBuffer->data->Resize (totalBytes);
		ov_clear (&oggFile);
		
		#undef BUFFER_SIZE
		#undef BUFFER_READ_TYPE
		
		return true;
		
	}
	
	
}