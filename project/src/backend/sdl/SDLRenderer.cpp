#include "SDLWindow.h"
#include "SDLRenderer.h"
#include "../../graphics/opengl/OpenGLBindings.h"


namespace lime {
	
	
	SDLRenderer::SDLRenderer (Window* window) {
		
		currentWindow = window;
		sdlWindow = ((SDLWindow*)window)->sdlWindow;
		
		if (OpenGLBindings::Init ()) {
			
			SDL_GLContext context = SDL_GL_CreateContext (sdlWindow);
			
			if (context) {
				
				SDL_GL_SetSwapInterval (0);
				SDL_GL_MakeCurrent (sdlWindow, context);
				
			}
			
		}
		
	}
	
	
	SDLRenderer::~SDLRenderer () {
		
		
		
	}
	
	
	void SDLRenderer::Flip () {
		
		SDL_GL_SwapWindow (sdlWindow);
		
	}
	
	
	Renderer* CreateRenderer (Window* window) {
		
		return new SDLRenderer (window);
		
	}
	
	
}