#include <hx/CFFI.h>
#include <ui/KeyEvent.h>


namespace lime {
	
	
	AutoGCRoot* KeyEvent::callback = 0;
	AutoGCRoot* KeyEvent::eventObject = 0;
	
	static int id_code;
	static int id_type;
	static bool init = false;
	
	
	KeyEvent::KeyEvent () {
		
		code = 0;
		type = KEY_DOWN;
		
	}
	
	
	void KeyEvent::Dispatch (KeyEvent* event) {
		
		if (KeyEvent::callback) {
			
			if (!init) {
				
				id_code = val_id ("code");
				id_type = val_id ("type");
				init = true;
				
			}
			
			value object = (KeyEvent::eventObject ? KeyEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_code, alloc_int (event->code));
			alloc_field (object, id_type, alloc_int (event->type));
			
			val_call1 (KeyEvent::callback->get (), object);
			
		}
		
	}
	
	
}