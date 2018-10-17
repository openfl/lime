#ifndef LIME_UTILS_RESOURCE_H
#define LIME_UTILS_RESOURCE_H


#include <system/CFFI.h>
#include <utils/Bytes.h>


namespace lime {


	struct Resource {


		Resource () : data (NULL), path (NULL) {}
		Resource (const char* path) : data (NULL), path (path) {}
		Resource (hl_vstring* path) : data (NULL), path (path ? hl_to_utf8 ((const uchar*)path->bytes) : NULL) {}
		Resource (Bytes* data) : data (data), path (NULL) {}

		Bytes* data;
		const char* path;


	};


}


#endif