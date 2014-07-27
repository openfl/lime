#ifndef LIME_IO_RESOURCE_H
#define LIME_IO_RESOURCE_H


#include <utils/ByteArray.h>


namespace lime {
	
	
	struct Resource {
		
		Resource (const char* path) { this->path = path; }
		Resource (ByteArray *data) { this->data = data; }
		
		ByteArray *data;
		const char* path;
		
	};
	
	
}


#endif