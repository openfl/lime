#include <hx/CFFI.h>
#include <ui/KeyEvent.h>


namespace lime {
	
	
	AutoGCRoot* KeyEvent::callback = 0;
	AutoGCRoot* KeyEvent::eventObject = 0;
	
	static double id_keyCode;
	static int id_modifier;
	static int id_type;
	static int id_windowID;
	static bool init = false;
	
	
	KeyEvent::KeyEvent () {
		
		keyCode = 0;
		modifier = 0;
		type = KEY_DOWN;
		windowID = 0;
		
	}
	
	
	void KeyEvent::Dispatch (KeyEvent* event) {
		
		if (KeyEvent::callback) {
			
			if (!init) {
				
				id_keyCode = val_id ("keyCode");
				id_modifier = val_id ("modifier");
				id_type = val_id ("type");
				id_windowID = val_id ("windowID");
				init = true;
				
			}
			
			value object = (KeyEvent::eventObject ? KeyEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_keyCode, alloc_float (event->keyCode));
			alloc_field (object, id_modifier, alloc_int (event->modifier));
			alloc_field (object, id_type, alloc_int (event->type));
			alloc_field (object, id_windowID, alloc_int (event->windowID));
			
			val_call0 (KeyEvent::callback->get ());
			
		}
		
	}
	
	
}