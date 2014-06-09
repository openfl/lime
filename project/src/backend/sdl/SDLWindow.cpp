#include "SDLWindow.h"


namespace lime {
	
	
	SDLWindow::SDLWindow (Application* application) {
		
		currentApplication = application;
		sdlWindow = SDL_CreateWindow ("Test", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 800, 600, SDL_WINDOW_OPENGL);
		
	}
	
	
	SDLWindow::~SDLWindow () {
		
		
		
	}
	
	
	Window* CreateWindow (Application* application) {
		
		return new SDLWindow (application);
		
	}
	
	
}