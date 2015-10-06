#include <hx/CFFI.h>
#include <ui/JoystickEvent.h>


namespace lime {
	
	
	AutoGCRoot* JoystickEvent::callback = 0;
	AutoGCRoot* JoystickEvent::eventObject = 0;
	
	static int id_id;
	static int id_index;
	static int id_type;
	static int id_value;
	static int id_x;
	static int id_y;
	static bool init = false;
	
	
	JoystickEvent::JoystickEvent () {
		
		id = 0;
		index = 0;
		eventValue = 0;
		x = 0;
		y = 0;
		type = JOYSTICK_AXIS_MOVE;
		
	}
	
	
	void JoystickEvent::Dispatch (JoystickEvent* event) {
		
		if (JoystickEvent::callback) {
			
			if (!init) {
				
				id_id = val_id ("id");
				id_index = val_id ("index");
				id_type = val_id ("type");
				id_value = val_id ("value");
				id_x = val_id ("x");
				id_y = val_id ("y");
				init = true;
				
			}
			
			value object = (JoystickEvent::eventObject ? JoystickEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_id, alloc_int (event->id));
			alloc_field (object, id_index, alloc_int (event->index));
			alloc_field (object, id_type, alloc_int (event->type));
			alloc_field (object, id_value, alloc_float (event->eventValue));
			alloc_field (object, id_x, alloc_int (event->x));
			alloc_field (object, id_y, alloc_int (event->y));
			
			val_call0 (JoystickEvent::callback->get ());
			
		}
		
	}
	
	
}