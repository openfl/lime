#include <hx/CFFI.h>
#include <graphics/RenderEvent.h>


namespace lime {
	
	
	AutoGCRoot* RenderEvent::callback = 0;
	AutoGCRoot* RenderEvent::eventObject = 0;
	
	//static int id_type;
	//static bool init = false;
	
	
	RenderEvent::RenderEvent () {
		
		type = RENDER;
		
	}
	
	
	void RenderEvent::Dispatch (RenderEvent* event) {
		
		if (RenderEvent::callback) {
			
			//if (!init) {
				
				//id_type = val_id ("type");
				
			//}
			
			value object = (RenderEvent::eventObject ? RenderEvent::eventObject->get () : alloc_empty_object ());
			
			//alloc_field (object, id_type, alloc_int (event->type));
			
			val_call0 (RenderEvent::callback->get ());
			
		}
		
	}
	
	
}