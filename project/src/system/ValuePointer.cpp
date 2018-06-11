#include <system/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {
	
	
	ValuePointer::ValuePointer (value handle) {
		
		cffiRoot = 0;
		cffiValue = alloc_root ();
		
		if (cffiValue) {
			
			*cffiValue = handle;
			
		} else {
			
			cffiRoot = create_root (handle);
			
		}
		
		hlValue = 0;
		
	}
	
	
	ValuePointer::ValuePointer (vobj* handle) {
		
		hlValue = handle;
		hl_add_root (&hlValue);
		
		cffiRoot = 0;
		cffiValue = 0;
		
	}
	
	
	ValuePointer::ValuePointer (vdynamic* handle) {
		
		hlValue = (vobj*)handle;
		hl_add_root (&hlValue);
		
		cffiRoot = 0;
		cffiValue = 0;
		
	}
	
	
	ValuePointer::ValuePointer (vclosure* callback) {
		
		hlValue = (vobj*)callback;
		hl_add_root (&hlValue);
		
		cffiRoot = 0;
		cffiValue = 0;
		
	}
	
	
	ValuePointer::~ValuePointer () {
		
		if (cffiValue) {
			
			free_root (cffiValue);
			
		} else if (cffiRoot) {
			
			destroy_root (cffiRoot);
			
		} else if (hlValue) {
			
			hl_remove_root (&hlValue);
			
		}
		
	}
	
	
	void* ValuePointer::Call () {
		
		if (!hlValue) {
			
			return val_call0 ((value)Get ());
			
		} else {
			
			return hl_dyn_call ((vclosure*)hlValue, 0, 0);
			
		}
		
	}
	
	
	void* ValuePointer::Call (void* arg0) { return 0; }
	void* ValuePointer::Call (void* arg0, void* arg1) { return 0; }
	void* ValuePointer::Call (void* arg0, void* arg1, void* arg2) { return 0; }
	void* ValuePointer::Call (void* arg0, void* arg1, void* arg2, void* arg3) { return 0; }
	void* ValuePointer::Call (void* arg0, void* arg1, void* arg2, void* arg3, void* arg4) { return 0; }
	
	
	void* ValuePointer::Get () const {
		
		if (cffiValue) {
			
			return *cffiValue;
			
		} else if (cffiRoot) {
			
			return query_root (cffiRoot);
			
		} else if (hlValue) {
			
			return hlValue;
			
		}
		
		return 0;
		
	}
	
	
	bool ValuePointer::IsCFFIValue () {
		
		return hlValue == 0;
		
	}
	
	
	bool ValuePointer::IsHLValue () {
		
		return hlValue != 0;
		
	}
	
	
	void ValuePointer::Set (value handle) {
		
		if (cffiValue) {
			
			*cffiValue = handle;
			
		} else {
			
			if (cffiRoot) destroy_root (cffiRoot);
			cffiRoot = create_root (handle);
			
		}
		
	}
	
	
	void ValuePointer::Set (vobj* handle) {
		
		hlValue = handle;
		
	}
	
	
}