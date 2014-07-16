#ifndef LIME_CONSOLE_RENDERER_H
#define LIME_CONSOLE_RENDERER_H


#include <graphics/Renderer.h>


namespace lime {
	
	
	class ConsoleRenderer : public Renderer {
		
		public:
			
			ConsoleRenderer (Window* window);
			~ConsoleRenderer ();
			
			virtual void Flip ();
		
	};
	
	
}


#endif