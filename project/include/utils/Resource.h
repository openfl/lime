#ifndef LIME_UTILS_RESOURCE_H
#define LIME_UTILS_RESOURCE_H


#include <utils/Bytes.h>


namespace lime {
	
	
	struct Resource {
		
		
		Resource () : data (NULL), path (NULL) {}
		Resource (const char* path) : data (NULL), path (path) {}
		Resource (Bytes *data) : data (data), path (NULL) {}
		
		Bytes *data;
		const char* path;
		
		
	};
	
	
}


#endif