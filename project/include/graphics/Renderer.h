#ifndef LIME_GRAPHICS_RENDERER_H
#define LIME_GRAPHICS_RENDERER_H


#include <ui/Window.h>


namespace lime {
	
	
	class Renderer {
		
		
		public:
			
			virtual void Flip () = 0;
			
			Window* currentWindow;
		
		
	};
	
	
	Renderer* CreateRenderer (Window* window);
	
	
}


#endif