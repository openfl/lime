#ifndef LIME_UI_WINDOW_H
#define LIME_UI_WINDOW_H


#ifdef CreateWindow
#undef CreateWindow
#endif

#include <app/Application.h>


namespace lime {
	
	
	class Window {
		
		
		public:
			
			Application* currentApplication;
		
		
	};
	
	
	Window* CreateWindow (Application* application, int width, int height, int flags);
	
	
}


#endif