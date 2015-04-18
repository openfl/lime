#include <hx/CFFI.h>
#include <ui/TextEvent.h>


namespace lime {
	
	
	AutoGCRoot* TextEvent::callback = 0;
	AutoGCRoot* TextEvent::eventObject = 0;
	
	static int id_text;
	static bool init = false;
	
	
	TextEvent::TextEvent () {
		
	}
	
	
	void TextEvent::Dispatch (TextEvent* event) {
		
		if (TextEvent::callback) {
			
			if (!init) {
				
				id_text = val_id ("text");
				init = true;
				
			}
			
			value object = (TextEvent::eventObject ? TextEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_text, alloc_string (event->text));
			
			val_call0 (TextEvent::callback->get ());
			
		}
		
	}
	
	
}
