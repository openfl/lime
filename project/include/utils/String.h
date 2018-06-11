#ifndef LIME_UTILS_STRING_H
#define LIME_UTILS_STRING_H


#include <system/CFFI.h>


namespace lime {
	
	
	struct HL_String {
		
		hl_type* t;
		unsigned char* bytes;
		int length;
		
	};
	
	
}


#endif