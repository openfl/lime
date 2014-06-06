#include "SDLWindow.h"
#include "SDLRenderer.h"


namespace lime {
	
	
	SDLRenderer::SDLRenderer (Window* window) {
		
		currentWindow = window;
		sdlRenderer = SDL_CreateRenderer (((SDLWindow*)window)->sdlWindow, -1, 0);
		
	}
	
	
	SDLRenderer::~SDLRenderer () {
		
		
		
	}
	
	
	Renderer* CreateRenderer (Window* window) {
		
		return new SDLRenderer (window);
		
	}
	
	
}