#ifndef LIME_UTILS_COMPRESS_LZMA_H
#define LIME_UTILS_COMPRESS_LZMA_H


#include <utils/Bytes.h>


namespace lime {


	class LZMA {


		public:

			static void Compress (Bytes* data, Bytes* result);
			static void Decompress (Bytes* data, Bytes* result);


	};


}


#endif