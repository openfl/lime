#ifndef LIME_GRAPHICS_RENDER_EVENT_H
#define LIME_GRAPHICS_RENDER_EVENT_H


#include <hl.h>
#include <hx/CFFI.h>


namespace lime {
	
	
	enum RenderEventType {
		
		RENDER,
		RENDER_CONTEXT_LOST,
		RENDER_CONTEXT_RESTORED
		
	};
	
	
	struct HL_RenderEvent {
		
		hl_type* t;
		RenderEventType type;
		
	};
	
	
	class RenderEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			RenderEvent ();
			
			static void Dispatch (RenderEvent* event);
			
			RenderEventType type;
		
	};
	
	
}


#endif