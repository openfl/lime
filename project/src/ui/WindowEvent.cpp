#include <hx/CFFI.h>
#include <ui/WindowEvent.h>


namespace lime {
	
	
	AutoGCRoot* WindowEvent::callback = 0;
	AutoGCRoot* WindowEvent::eventObject = 0;
	
	static int id_type;
	static bool init = false;
	
	
	WindowEvent::WindowEvent () {
		
		type = WINDOW_ACTIVATE;
		
	}
	
	
	void WindowEvent::Dispatch (WindowEvent* event) {
		
		if (WindowEvent::callback) {
			
			if (!init) {
				
				id_type = val_id ("type");
				init = true;
				
			}
			
			value object = (WindowEvent::eventObject ? WindowEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_type, alloc_int (event->type));
			
			val_call1 (WindowEvent::callback->get (), object);
			
		}
		
	}
	
	
}