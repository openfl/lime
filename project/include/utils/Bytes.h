#ifndef LIME_UTILS_BYTES_H
#define LIME_UTILS_BYTES_H


#include <system/CFFI.h>
#include <utils/QuickVec.h>


namespace lime {
	
	
	struct HL_Bytes {
		
		hl_type* t;
		int length;
		unsigned char* b;
		
	};
	
	
	struct Bytes {
		
		
		Bytes ();
		Bytes (int size);
		Bytes (value bytes);
		Bytes (HL_Bytes* bytes);
		Bytes (const char* path);
		Bytes (const QuickVec<unsigned char> data);
		~Bytes ();
		
		unsigned char *Data ();
		const unsigned char *Data () const;
		int Length () const;
		void ReadFile (const char* path);
		void Resize (int size);
		void Set (value bytes);
		void Set (HL_Bytes* bytes);
		void Set (const QuickVec<unsigned char> data);
		value Value ();
		
		unsigned char *_data;
		int _length;
		value _value;
		
		
	};
	
	
}


#endif