#ifndef LIME_WINDOW_H
#define LIME_WINDOW_H


#include "Application.h"


namespace lime {
	
	
	class Window {
		
		
		public:
			
			Application* currentApplication;
		
		
	};
	
	
	Window* CreateWindow (Application* application);
	
	
}


#endif