#include <hx/CFFI.h>
#include <ui/MouseEvent.h>


namespace lime {
	
	
	AutoGCRoot* MouseEvent::callback = 0;
	AutoGCRoot* MouseEvent::eventObject = 0;
	
	static int id_id;
	static int id_type;
	static int id_x;
	static int id_y;
	static bool init = false;
	
	
	MouseEvent::MouseEvent () {
		
		id = 0;
		type = MOUSE_DOWN;
		x = 0;
		y = 0;
		
	}
	
	
	void MouseEvent::Dispatch (MouseEvent* event) {
		
		if (MouseEvent::callback) {
			
			if (!init) {
				
				id_id = val_id ("id");
				id_type = val_id ("type");
				id_x = val_id ("x");
				id_y = val_id ("y");
				init = true;
				
			}
			
			value object = (MouseEvent::eventObject ? MouseEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_id, alloc_int (event->id));
			alloc_field (object, id_type, alloc_int (event->type));
			alloc_field (object, id_x, alloc_float (event->x));
			alloc_field (object, id_y, alloc_float (event->y));
			
			val_call1 (MouseEvent::callback->get (), object);
			
		}
		
	}
	
	
}