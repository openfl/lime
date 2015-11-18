#include <hx/CFFI.h>
#include <ui/WindowEvent.h>


namespace lime {
	
	
	AutoGCRoot* WindowEvent::callback = 0;
	AutoGCRoot* WindowEvent::eventObject = 0;
	
	static int id_height;
	static int id_type;
	static int id_width;
	static int id_windowID;
	static int id_x;
	static int id_y;
	static bool init = false;
	
	
	WindowEvent::WindowEvent () {
		
		type = WINDOW_ACTIVATE;
		
		width = 0;
		height = 0;
		windowID = 0;
		x = 0;
		y = 0;
		
	}
	
	
	void WindowEvent::Dispatch (WindowEvent* event) {
		
		if (WindowEvent::callback) {
			
			if (!init) {
				
				id_height = val_id ("height");
				id_type = val_id ("type");
				id_width = val_id ("width");
				id_windowID = val_id ("windowID");
				id_x = val_id ("x");
				id_y = val_id ("y");
				init = true;
				
			}
			
			value object = (WindowEvent::eventObject ? WindowEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_type, alloc_int (event->type));
			alloc_field (object, id_windowID, alloc_int (event->windowID));
			
			switch (event->type) {
				
				case WINDOW_MOVE:
					
					alloc_field (object, id_x, alloc_int (event->x));
					alloc_field (object, id_y, alloc_int (event->y));
					break;
				
				case WINDOW_RESIZE:
					
					alloc_field (object, id_width, alloc_int (event->width));
					alloc_field (object, id_height, alloc_int (event->height));
					break;
				
				default: break;
				
			}
			
			val_call0 (WindowEvent::callback->get ());
			
		}
		
	}
	
	
}