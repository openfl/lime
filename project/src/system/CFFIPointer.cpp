#include <system/CFFIPointer.h>


namespace lime {


	value CFFIPointer (void* ptr, hx::finalizer finalizer) {

		if (ptr) {

			value handle = cffi::alloc_pointer (ptr);

			if (finalizer) {

				val_gc (handle, finalizer);

			}

			return handle;

		} else {

			return alloc_null ();

		}

	}


	value CFFIPointer (value handle, hx::finalizer finalizer) {

		if (!val_is_null (handle) && finalizer) {

			val_gc (handle, finalizer);

		}

		return handle;

	}


	HL_CFFIPointer* HLCFFIPointer (void* handle, hl_finalizer finalizer) {

		if (handle) {

			HL_CFFIPointer* pointer = (HL_CFFIPointer*)hl_gc_alloc_finalizer (sizeof (HL_CFFIPointer));
			pointer->finalizer = finalizer ? (void*)finalizer : 0;
			pointer->ptr = handle;
			return pointer;

		} else {

			return 0;

		}

	}


}