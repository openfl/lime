#ifndef LIME_RENDERER_H
#define LIME_RENDERER_H


#include "Window.h"


namespace lime {
	
	
	class Renderer {
		
		
		public:
			
			Window* currentWindow;
		
		
	};
	
	
	Renderer* CreateRenderer (Window* window);
	
	
}


#endif