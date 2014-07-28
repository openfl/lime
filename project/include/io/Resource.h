#ifndef LIME_IO_RESOURCE_H
#define LIME_IO_RESOURCE_H


#include <utils/ByteArray.h>


namespace lime {
	
	
	struct Resource {
		
		
		Resource (const char* path) : data (NULL), path (path) {}
		Resource (ByteArray *data) : data (data), path (NULL) {}
		
		ByteArray *data;
		const char* path;
		
		
	};
	
	
}


#endif