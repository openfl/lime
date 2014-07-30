#ifndef LIME_UTILS_RESOURCE_H
#define LIME_UTILS_RESOURCE_H


#include <utils/ByteArray.h>


namespace lime {
	
	
	struct Resource {
		
		
		Resource () : data (NULL), path (NULL) {}
		Resource (const char* path) : data (NULL), path (path) {}
		Resource (ByteArray *data) : data (data), path (NULL) {}
		
		ByteArray *data;
		const char* path;
		
		
	};
	
	
}


#endif