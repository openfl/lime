#include "SDLWindow.h"
#include <stdio.h>


namespace lime {
	
	
	SDLWindow::SDLWindow (Application* application) {
		
		currentApplication = application;
		sdlWindow = SDL_CreateWindow ("Test", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 800, 600, 0);
		
	}
	
	
	SDLWindow::~SDLWindow () {
		
		
		
	}
	
	
	Window* CreateWindow (Application* application) {
		
		return new SDLWindow (application);
		
	}
	
	
}