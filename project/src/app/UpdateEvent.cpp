#include <hx/CFFI.h>
#include <app/UpdateEvent.h>


namespace lime {
	
	
	AutoGCRoot* UpdateEvent::callback = 0;
	AutoGCRoot* UpdateEvent::eventObject = 0;
	
	static int id_deltaTime;
	//static int id_type;
	static bool init = false;
	
	
	UpdateEvent::UpdateEvent () {
		
		deltaTime = 0;
		type = UPDATE;
		
	}
	
	
	void UpdateEvent::Dispatch (UpdateEvent* event) {
		
		if (UpdateEvent::callback) {
			
			if (!init) {
				
				id_deltaTime = val_id ("deltaTime");
				//id_type = val_id ("type");
				init = true;
				
			}
			
			value object = (UpdateEvent::eventObject ? UpdateEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_deltaTime, alloc_int (event->deltaTime));
			//alloc_field (object, id_type, alloc_int (event->type));
			
			val_call0 (UpdateEvent::callback->get ());
			
		}
		
	}
	
	
}