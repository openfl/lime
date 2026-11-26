#include <utils/compress/Zlib.h>
#include <system/System.h>
#include <limits.h>
#include <string.h>
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


	static void Deflate (ZlibType type, Bytes* data, Bytes* result, int level);
	static bool Inflate (ZlibType type, Bytes* data, Bytes* result);


	// zlib only reads the input and writes the result's own memory, so the
	// collector needn't wait for this thread: compressing on a worker thread
	// otherwise holds up every collection until it finishes
	void Zlib::Compress (ZlibType type, Bytes* data, Bytes* result, int level) {

		// No level is the best compression, as before levels could be chosen
		if (level < 0) level = Z_BEST_COMPRESSION;
		if (level > Z_BEST_COMPRESSION) level = Z_BEST_COMPRESSION;

		System::GCEnterBlocking ();
		Deflate (type, data, result, level);
		System::GCExitBlocking ();

	}


	bool Zlib::Decompress (ZlibType type, Bytes* data, Bytes* result) {

		System::GCEnterBlocking ();
		bool decompressed = Inflate (type, data, result);
		System::GCExitBlocking ();

		return decompressed;

	}


	static void Deflate (ZlibType type, Bytes* data, Bytes* result, int level) {

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


	static bool Inflate (ZlibType type, Bytes* data, Bytes* result) {

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

		stream.avail_in = data->length;
		stream.next_in = data->b;

		// zlib inflates straight into the result, which grows by doubling and is
		// trimmed at the end: growing it to fit each chunk in turn copied
		// everything inflated so far for every chunk
		const int chunkSize = 1 << 16;
		int capacity = 0;
		int readTotal = 0;
		int members = 0;
		bool finished = false;
		bool failed = false;

		while (!finished && !failed) {

			if (capacity - readTotal < chunkSize) {

				if (capacity == INT_MAX) {

					failed = true;
					break;

				}

				int grown = capacity < chunkSize ? chunkSize : (capacity > INT_MAX / 2 ? INT_MAX : capacity * 2);

				if (!result->TryResize (grown)) {

					failed = true;
					break;

				}

				capacity = grown;

			}

			stream.avail_out = capacity - readTotal;
			stream.next_out = result->b + readTotal;

			int ret = inflate (&stream, Z_NO_FLUSH);
			readTotal = capacity - stream.avail_out;

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

		if (result->length != readTotal) {

			result->TryResize (readTotal);

		}

		return !failed;

	}


}