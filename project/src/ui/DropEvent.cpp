#include <hx/CFFI.h>
#include <ui/DropEvent.h>


namespace lime {
	
	
	AutoGCRoot* DropEvent::callback = 0;
	AutoGCRoot* DropEvent::eventObject = 0;
	
	static int id_file;
	static int id_type;
	static bool init = false;
	
	
	DropEvent::DropEvent () {
    
    type = DROP_FILE;
		
	}
	
	
	void DropEvent::Dispatch (DropEvent* event) {
		
		if (DropEvent::callback)
    {
			
      if (!init)
      {
        id_file = val_id("file");
        id_type = val_id("type");
        init = true;
      }
      
      value object = (DropEvent::eventObject ? DropEvent::eventObject->get() : alloc_empty_object());
      
      alloc_field(object, id_file, alloc_string(event->file));
			alloc_field(object, id_type, alloc_int (event->type));
			
			val_call0 (DropEvent::callback->get ());
			
		}
		
	}
	
	
}