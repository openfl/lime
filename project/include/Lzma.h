#ifndef LIME_LZMA_H
#define LIME_LZMA_H

#include <hx/CFFI.h>

namespace lime {

	class Lzma {
		public:
		
			static void Encode(buffer input_buffer, buffer output_buffer);
			static void Decode(buffer input_buffer, buffer output_buffer);
	};
	
}

#endif