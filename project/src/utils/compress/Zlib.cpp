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


	void Zlib::Compress (ZlibType type, Bytes* data, Bytes* result, int level) {

		// No level is the best compression, as before levels could be chosen
		if (level < 0) level = Z_BEST_COMPRESSION;
		if (level > Z_BEST_COMPRESSION) level = Z_BEST_COMPRESSION;

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

		if ((ret = deflateInit2 (stream, level, Z_DEFLATED, windowBits, 8, Z_DEFAULT_STRATEGY) != Z_OK)) {

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


	bool Zlib::Decompress (ZlibType type, Bytes* data, Bytes* result) {

		// An empty input is no stream at all
		if (!data->b || data->length <= 0) return false;

		int windowBits = 15;

		switch (type) {

			case DEFLATE: windowBits = -15; break;
			case GZIP: windowBits = 31; break;
			default: break;

		}

		z_stream stream;
		stream.zalloc = Z_NULL;
		stream.zfree = Z_NULL;
		stream.opaque = Z_NULL;
		stream.avail_in = 0;
		stream.next_in = Z_NULL;

		if (inflateInit2 (&stream, windowBits) != Z_OK) {

			return false;

		}

		const int chunkSize = 1 << 16;
		Bytef* buffer = (Bytef*)malloc (chunkSize);

		if (!buffer) {

			inflateEnd (&stream);
			return false;

		}

		stream.avail_in = data->length;
		stream.next_in = data->b;

		int readTotal = 0;
		int members = 0;
		bool finished = false;
		bool failed = false;

		while (!finished && !failed) {

			stream.avail_out = chunkSize;
			stream.next_out = buffer;

			int ret = inflate (&stream, Z_NO_FLUSH);
			int readSize = chunkSize - stream.avail_out;

			if (readSize > 0) {

				if (!result->TryResize (readTotal + readSize)) {

					failed = true;
					break;

				}

				memcpy (result->b + readTotal, buffer, readSize);
				readTotal += readSize;

			}

			switch (ret) {

				case Z_OK:

					break;

				case Z_STREAM_END:

					members++;

					// RFC 1952 makes a gzip file a series of members
					if (type == GZIP && stream.avail_in > 0) {

						inflateReset (&stream);

					} else {

						finished = true;

					}

					break;

				case Z_DATA_ERROR:

					// After a gzip file's last member, data that isn't another member
					// is left alone, as gzip does with the zeros some tools pad with
					if (type == GZIP && members > 0 && stream.total_out == 0) {

						finished = true;

					} else {

						failed = true;

					}

					break;

				default:

					// Z_BUF_ERROR: the input ended before the stream did. Z_NEED_DICT,
					// Z_MEM_ERROR and Z_STREAM_ERROR can't be got past either.
					failed = true;
					break;

			}

		}

		inflateEnd (&stream);
		free (buffer);

		return !failed;

	}


}