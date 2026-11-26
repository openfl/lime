#ifndef LIME_UTILS_COMPRESS_ZLIB_H
#define LIME_UTILS_COMPRESS_ZLIB_H


#include <utils/Bytes.h>


namespace lime {


	enum ZlibType {

		DEFLATE,
		GZIP,
		ZLIB

	};


	class Zlib {


		public:

			static void Compress (ZlibType type, Bytes* data, Bytes* result, int level = -1);
			static bool Decompress (ZlibType type, Bytes* data, Bytes* result);


	};


}


#endif