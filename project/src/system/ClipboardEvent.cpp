#include <hx/CFFI.h>
#include <system/ClipboardEvent.h>


namespace lime {
	
	
	AutoGCRoot* ClipboardEvent::callback = 0;
	AutoGCRoot* ClipboardEvent::eventObject = 0;
	
	static int id_type;
	static bool init = false;
	
	
	ClipboardEvent::ClipboardEvent () {
		
		type = CLIPBOARD_UPDATE;
		
	}
	
	
	void ClipboardEvent::Dispatch (ClipboardEvent* event) {
		
		if (ClipboardEvent::callback) {
			
			if (!init) {
				
				id_type = val_id ("type");
				init = true;
				
			}
			
			value object = (ClipboardEvent::eventObject ? ClipboardEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_type, alloc_int (event->type));
			
			val_call0 (ClipboardEvent::callback->get ());
			
		}
		
	}
	
	
}