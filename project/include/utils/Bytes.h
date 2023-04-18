#ifndef LIME_UTILS_BYTES_H
#define LIME_UTILS_BYTES_H


#include <system/CFFI.h>
#include <utils/QuickVec.h>


namespace lime {


	struct Bytes {

		hl_type* t;
		int length;
		unsigned char* b;

		Bytes ();
		Bytes (value bytes);
		~Bytes ();

		void ReadFile (const char* path);
		void Resize (int size);
		void Set (value bytes);
		void Set (const QuickVec<unsigned char> data);
		value Value (value bytes);
		value Value ();

	};


}


#endif