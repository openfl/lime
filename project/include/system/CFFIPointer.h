#ifndef LIME_SYSTEM_CFFI_POINTER_H
#define LIME_SYSTEM_CFFI_POINTER_H


#include <system/CFFI.h>


namespace hx {

	class Object;
	typedef void (*finalizer)(value v);

}


namespace lime {


	struct HL_CFFIPointer {

		void* finalizer;
		void* ptr;

	};

	typedef void (*hl_finalizer)(void* v);


	value CFFIPointer (void* ptr, hx::finalizer finalizer = 0);
	value CFFIPointer (value handle, hx::finalizer finalizer = 0);
	HL_CFFIPointer* HLCFFIPointer (void* ptr, hl_finalizer finalizer = 0);


}


#endif