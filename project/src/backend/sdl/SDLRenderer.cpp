#include "SDLWindow.h"
#include "SDLRenderer.h"
#include "../../graphics/OpenGLBindings.h"


namespace lime {
	
	
	SDLRenderer::SDLRenderer (Window* window) {
		
		currentWindow = window;
		sdlWindow = ((SDLWindow*)window)->sdlWindow;
		
		if (OpenGLBindings::Init ()) {
			
			SDL_GLContext context = SDL_GL_CreateContext (sdlWindow);
			
			if (context) {
				
				if (window->flags & WINDOW_FLAG_VSYNC) {
					
					SDL_GL_SetSwapInterval (1);
					
				} else {
					
					SDL_GL_SetSwapInterval (0);
					
				}
				
				if (window->flags & WINDOW_FLAG_DEPTH_BUFFER) {
					
					SDL_GL_SetAttribute (SDL_GL_DEPTH_SIZE, 32 - (window->flags & WINDOW_FLAG_STENCIL_BUFFER) ? 8 : 0);
					
				}
				
				if (window->flags & WINDOW_FLAG_STENCIL_BUFFER) {
					
					SDL_GL_SetAttribute (SDL_GL_STENCIL_SIZE, 8);
					
				}
				
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