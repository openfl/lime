#include <hx/CFFI.h>
#include <ui/DropEvent.h>


namespace lime {
	
	
	ValuePointer* DropEvent::callback = 0;
	ValuePointer* DropEvent::eventObject = 0;
	
	static int id_file;
	static int id_type;
	static bool init = false;
	
	
	DropEvent::DropEvent () {
		
		file = 0;
		type = DROP_FILE;
		
	}
	
	
	void DropEvent::Dispatch (DropEvent* event) {
		
		if (DropEvent::callback) {
			
			if (DropEvent::eventObject->IsCFFIValue ()) {
				
				if (!init) {
					
					id_file = val_id ("file");
					id_type = val_id ("type");
					init = true;
					
				}
				
				value object = (value)DropEvent::eventObject->Get ();
				
				alloc_field (object, id_file, alloc_string (event->file));
				alloc_field (object, id_type, alloc_int (event->type));
				
			} else {
				
				HL_DropEvent* eventObject = (HL_DropEvent*)DropEvent::eventObject->Get ();
				
				// TODO
				// eventObject->file = event->file;
				eventObject->type = event->type;
				
			}
			
			DropEvent::callback->Call ();
			
		}
		
	}
	
	
}