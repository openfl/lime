#include "SDLApplication.h"


namespace lime {
	
	
	SDLApplication::SDLApplication () {
		
		SDL_Init (SDL_INIT_VIDEO);
		
	}
	
	
	SDLApplication::~SDLApplication () {
		
		
		
	}
	
	
	int SDLApplication::Exec () {
		
		SDL_Event event;
		bool active = true;
		
		while (active) {
			
			while (active && SDL_WaitEvent (&event)) {
				
				if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE) {
					
					active = false;
					break;
					
				}
				
			}
			
			while (active && SDL_PollEvent (&event)) {
				
				if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE) {
					
					active = false;
					break;
					
				}
				
			}
			
		}
		
		SDL_Quit ();
		
		return 0;
		
	}
	
	
	Application* CreateApplication () {
		
		return new SDLApplication ();
		
	}
	
	
}