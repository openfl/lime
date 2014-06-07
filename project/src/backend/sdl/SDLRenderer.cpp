#include "SDLWindow.h"
#include "SDLRenderer.h"
#include <SDL_opengl.h>


namespace lime {
	
	
	void InitOpenGLBindings ();
	
	
	
	SDLRenderer::SDLRenderer (Window* window) {
		
		currentWindow = window;
		sdlRenderer = SDL_CreateRenderer (((SDLWindow*)window)->sdlWindow, -1, SDL_RENDERER_ACCELERATED);
		
		InitOpenGLBindings ();
		
	}
	
	
	SDLRenderer::~SDLRenderer () {
		
		
		
	}
	
	
	Renderer* CreateRenderer (Window* window) {
		
		return new SDLRenderer (window);
		
	}
	
	
}