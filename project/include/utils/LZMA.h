#ifndef LIME_UTILS_LZMA_H
#define LIME_UTILS_LZMA_H


#include <utils/Bytes.h>


namespace lime {
	
	
	class LZMA {
		
		
		public:
			
			static void Decode (Bytes* data, Bytes* result);
			static void Encode (Bytes* data, Bytes* result);
		
		
	};
	
	
}


#endif