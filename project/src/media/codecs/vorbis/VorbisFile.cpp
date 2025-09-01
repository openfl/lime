#include <media/codecs/vorbis/VorbisFile.h>
#include <system/System.h>


namespace lime {


	typedef struct {

		unsigned char* data;
		ogg_int64_t size;
		ogg_int64_t pos;

	} VorbisFile_Buffer;


	static size_t VorbisFile_BufferRead (void* dest, size_t eltSize, size_t nelts, VorbisFile_Buffer* src) {

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


	static int VorbisFile_BufferSeek (VorbisFile_Buffer* src, ogg_int64_t pos, int whence) {

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


	static int VorbisFile_BufferClose (VorbisFile_Buffer* src) {

		delete src;
		return 0;

	}


	static long VorbisFile_BufferTell (VorbisFile_Buffer* src) {

		return src->pos;

	}


	static ov_callbacks VORBIS_FILE_BUFFER_CALLBACKS = {

		(size_t (*)(void *, size_t, size_t, void *)) VorbisFile_BufferRead,
		(int (*)(void *, ogg_int64_t, int)) VorbisFile_BufferSeek,
		(int (*)(void *)) VorbisFile_BufferClose,
		(long (*)(void *)) VorbisFile_BufferTell

	};


	static size_t VorbisFile_FileRead (void* dest, size_t eltSize, size_t nelts, FILE_HANDLE* file) {

		return lime::fread (dest, eltSize, nelts, file);

	}


	static int VorbisFile_FileSeek (FILE_HANDLE* file, ogg_int64_t pos, int whence) {

		return lime::fseek (file, pos, whence);

	}


	static int VorbisFile_FileClose (FILE_HANDLE* file) {

		return lime::fclose (file);

	}


	static long VorbisFile_FileTell (FILE_HANDLE* file) {

		return lime::ftell (file);

	}


	static ov_callbacks VORBIS_FILE_FILE_CALLBACKS = {

		(size_t (*)(void *, size_t, size_t, void *)) VorbisFile_FileRead,
		(int (*)(void *, ogg_int64_t, int)) VorbisFile_FileSeek,
		(int (*)(void *)) VorbisFile_FileClose,
		(long (*)(void *)) VorbisFile_FileTell

	};


	OggVorbis_File* VorbisFile::FromBytes (Bytes* bytes) {

		OggVorbis_File* vorbisFile = new OggVorbis_File;
		memset (vorbisFile, 0, sizeof (OggVorbis_File));

		VorbisFile_Buffer* buffer = new VorbisFile_Buffer ();
		buffer->data = bytes->b;
		buffer->size = bytes->length;
		buffer->pos = 0;

		if (ov_open_callbacks (buffer, vorbisFile, NULL, 0, VORBIS_FILE_BUFFER_CALLBACKS) != 0) {

			delete buffer;
			delete vorbisFile;
			return 0;

		}

		return vorbisFile;

	}


	OggVorbis_File* VorbisFile::FromFile (const char* path) {

		if (path) {

			FILE_HANDLE *file = lime::fopen (path, "rb");

			if (file) {

				OggVorbis_File* vorbisFile = new OggVorbis_File;
				memset (vorbisFile, 0, sizeof (OggVorbis_File));

				if (ov_open_callbacks (file, vorbisFile, NULL, 0, VORBIS_FILE_FILE_CALLBACKS) != 0) {

					delete vorbisFile;
					lime::fclose (file);
					return 0;

				}

				return vorbisFile;

			}

		}

		return 0;

	}


}