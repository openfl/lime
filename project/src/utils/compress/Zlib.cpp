#include <utils/compress/Zlib.h>
#include <zlib.h>


#ifdef STATIC_LINK
extern "C" int zlib_register_prims()
{
   static bool init = false;
   if (init) return 0;
   init = true;

   return 0;
}
#endif

namespace lime {


	void Zlib::Compress (ZlibType type, Bytes* data, Bytes* result) {

		int windowBits = 15;

		switch (type) {

			case DEFLATE: windowBits = -15; break;
			case GZIP: windowBits = 31; break;
			default: break;

		}

		z_stream* stream = (z_stream*)malloc (sizeof (z_stream));
		stream->zalloc = Z_NULL;
		stream->zfree = Z_NULL;
		stream->opaque = Z_NULL;

		int ret = 0;

		if ((ret = deflateInit2 (stream, Z_BEST_COMPRESSION, Z_DEFLATED, windowBits, 8, Z_DEFAULT_STRATEGY) != Z_OK)) {

			//val_throw (stream->msg);
			free (stream);
			return;

		}

		int bufferSize = deflateBound (stream, data->length);
		char* buffer = (char*)malloc (bufferSize);

		stream->next_in = (Bytef*)data->b;
		stream->next_out = (Bytef*)buffer;
		stream->avail_in = data->length;
		stream->avail_out = bufferSize;

		if ((ret = deflate (stream, Z_FINISH)) < 0) {

			//if (stream && stream->msg) printf ("%s\n", stream->msg);
			//val_throw (stream->msg);
			deflateEnd (stream);
			free (stream);
			free (buffer);
			return;

		}

		int size = bufferSize - stream->avail_out;
		result->Resize (size);
		memcpy (result->b, buffer, size);
		deflateEnd (stream);
		free (stream);
		free (buffer);

		return;

	}


	void Zlib::Decompress (ZlibType type, Bytes* data, Bytes* result) {

		int windowBits = 15;

		switch (type) {

			case DEFLATE: windowBits = -15; break;
			case GZIP: windowBits = 31; break;
			default: break;

		}

		z_stream* stream = (z_stream*)malloc (sizeof (z_stream));
		stream->zalloc = Z_NULL;
		stream->zfree = Z_NULL;
		stream->opaque = Z_NULL;

		int ret = 0;

		if ((ret = inflateInit2 (stream, windowBits) != Z_OK)) {

			//val_throw (stream->msg);
			inflateEnd (stream);
			free (stream);
			return;

		}

		int chunkSize = 1 << 16;
		int readSize = 0;
		Bytef* sourcePosition = data->b;
		int destSize = 0;
		int readTotal = 0;

		Bytef* buffer = (Bytef*)malloc (chunkSize);

		stream->avail_in = data->length;
		stream->next_in = data->b;

		if (stream->avail_in > 0) {

			do {

				stream->avail_out = chunkSize;
				stream->next_out = buffer;

				ret = inflate (stream, Z_NO_FLUSH);

				if (ret == Z_STREAM_ERROR) {

					inflateEnd (stream);
					free (stream);
					free (buffer);
					return;

				}

				switch (ret) {

					case Z_NEED_DICT:
						ret = Z_DATA_ERROR;
					case Z_DATA_ERROR:
					case Z_MEM_ERROR:
						inflateEnd (stream);
						free (stream);
						free (buffer);
						return;

				}

				readSize = chunkSize - stream->avail_out;
				readTotal += readSize;

				result->Resize (readTotal);
				memcpy (result->b + readTotal - readSize, buffer, readSize);

				sourcePosition += readSize;

			} while (stream->avail_out == 0);

		}

		inflateEnd (stream);
		free (stream);
		free (buffer);

		return;

	}


}