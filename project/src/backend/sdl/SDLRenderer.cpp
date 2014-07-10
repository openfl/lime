#include "SDLWindow.h"
#include "SDLRenderer.h"
#include "../../graphics/OpenGLBindings.h"


namespace lime {
	
	
	SDLRenderer::SDLRenderer (Window* window) {
		
		currentWindow = window;
		sdlWindow = ((SDLWindow*)window)->sdlWindow;
		
		int sdlFlags = SDL_RENDERER_ACCELERATED;
		
		if (window->flags & WINDOW_FLAG_VSYNC) sdlFlags |= SDL_RENDERER_PRESENTVSYNC;
		
		if (window->flags & WINDOW_FLAG_DEPTH_BUFFER) {
			
			SDL_GL_SetAttribute (SDL_GL_DEPTH_SIZE, 32 - (window->flags & WINDOW_FLAG_STENCIL_BUFFER) ? 8 : 0);
			
		}
		
		if (window->flags & WINDOW_FLAG_STENCIL_BUFFER) {
			
			SDL_GL_SetAttribute (SDL_GL_STENCIL_SIZE, 8);
			
		}
		
		sdlRenderer = SDL_CreateRenderer (sdlWindow, -1, sdlFlags);
		
		OpenGLBindings::Init ();
		
	}
	
	
	SDLRenderer::~SDLRenderer () {
		
		
		
	}
	
	
	void SDLRenderer::Flip () {
		
		SDL_RenderPresent (sdlRenderer);
		
	}
	
	
	Renderer* CreateRenderer (Window* window) {
		
		return new SDLRenderer (window);
		
	}
	
	
}