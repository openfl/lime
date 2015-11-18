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
	
	
}