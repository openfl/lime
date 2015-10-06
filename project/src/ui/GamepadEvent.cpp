#include <hx/CFFI.h>
#include <ui/GamepadEvent.h>


namespace lime {
	
	
	AutoGCRoot* GamepadEvent::callback = 0;
	AutoGCRoot* GamepadEvent::eventObject = 0;
	
	static double id_axis;
	static int id_button;
	static int id_id;
	static int id_type;
	static int id_value;
	static bool init = false;
	
	
	GamepadEvent::GamepadEvent () {
		
		axis = 0;
		axisValue = 0;
		button = 0;
		id = 0;
		type = GAMEPAD_AXIS_MOVE;
		
	}
	
	
	void GamepadEvent::Dispatch (GamepadEvent* event) {
		
		if (GamepadEvent::callback) {
			
			if (!init) {
				
				id_axis = val_id ("axis");
				id_button = val_id ("button");
				id_id = val_id ("id");
				id_type = val_id ("type");
				id_value = val_id ("value");
				init = true;
				
			}
			
			value object = (GamepadEvent::eventObject ? GamepadEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_axis, alloc_int (event->axis));
			alloc_field (object, id_button, alloc_int (event->button));
			alloc_field (object, id_id, alloc_int (event->id));
			alloc_field (object, id_type, alloc_int (event->type));
			alloc_field (object, id_value, alloc_float (event->axisValue));
			
			val_call0 (GamepadEvent::callback->get ());
			
		}
		
	}
	
	
}