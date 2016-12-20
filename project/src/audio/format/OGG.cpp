#include <audio/format/OGG.h>
#include <system/System.h>
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
		Bytes *data = NULL;
		OAL_OggMemoryFile fakeFile;
		
		if (resource->path) {
			
			FILE_HANDLE *file = lime::fopen (resource->path, "rb");
			
			if (!file) {
				
				return false;
				
			}
			
			if (file->isFile ()) {
				
				if (ov_open (file->getFile (), &oggFile, NULL, file->getLength ()) != 0) {
					
					lime::fclose (file);
					return false;
					
				}
				
			} else {
				
				lime::fclose (file);
				data = new Bytes (resource->path);
				
				fakeFile = OAL_OggMemoryFile ();
				fakeFile.data = data->Data ();
				fakeFile.size = data->Length ();
				fakeFile.pos = 0;
				
				if (ov_open_callbacks (&fakeFile, &oggFile, NULL, 0, OAL_CALLBACKS_BUFFER) != 0) {
					
					delete data;
					return false;
					
				}
				
			}
			
		} else {
			
			fakeFile = OAL_OggMemoryFile ();
			fakeFile.data = resource->data->Data ();
			fakeFile.size = resource->data->Length ();
			fakeFile.pos = 0;
			
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
		
		#define BUFFER_SIZE 4096
		
		vorbis_info *pInfo = ov_info (&oggFile, -1);
		
		if (pInfo == NULL) {
			
			//LOG_SOUND("FAILED TO READ OGG SOUND INFO, IS THIS EVEN AN OGG FILE?\n");
			ov_clear (&oggFile);
			
			if (data) {
				
				delete data;
				
			}
			
			return false;
			
		}
		
		audioBuffer->channels = pInfo->channels;
		audioBuffer->sampleRate = pInfo->rate;
		
		audioBuffer->bitsPerSample = 16;
		
		int dataLength = ov_pcm_total (&oggFile, -1) * audioBuffer->channels * audioBuffer->bitsPerSample / 8;
		audioBuffer->data->Resize (dataLength);
		
		while (bytes > 0) {
			
			bytes = ov_read (&oggFile, (char *)audioBuffer->data->Data () + totalBytes, BUFFER_SIZE, BUFFER_READ_TYPE, 2, 1, &bitStream);
			totalBytes += bytes;
			
		}
		
		if (dataLength != totalBytes) {
			
			audioBuffer->data->Resize (totalBytes);
			
		}
		
		ov_clear (&oggFile);
		
		#undef BUFFER_READ_TYPE
		
		if (data) {
			
			delete data;
			
		}
		
		return true;
		
	}
	
	
}