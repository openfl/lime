#include <hx/CFFI.h>
#include <ui/KeyEvent.h>


namespace lime {
	
	
	AutoGCRoot* KeyEvent::callback = 0;
	AutoGCRoot* KeyEvent::eventObject = 0;
	
	static double id_keyCode;
	static int id_modifier;
	static int id_type;
	static bool init = false;
	
	
	KeyEvent::KeyEvent () {
		
		keyCode = 0;
		modifier = 0;
		type = KEY_DOWN;
		
	}
	
	
	void KeyEvent::Dispatch (KeyEvent* event) {
		
		if (KeyEvent::callback) {
			
			if (!init) {
				
				id_keyCode = val_id ("keyCode");
				id_modifier = val_id ("modifier");
				id_type = val_id ("type");
				init = true;
				
			}
			
			value object = (KeyEvent::eventObject ? KeyEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_keyCode, alloc_float (event->keyCode));
			alloc_field (object, id_modifier, alloc_int (event->modifier));
			alloc_field (object, id_type, alloc_int (event->type));
			
			val_call0 (KeyEvent::callback->get ());
			
		}
		
	}
	
	
}