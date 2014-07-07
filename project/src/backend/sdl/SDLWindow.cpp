#include "SDLWindow.h"


namespace lime {
	
	
	SDLWindow::SDLWindow (Application* application, int width, int height, int flags) {
		
		currentApplication = application;
		
		// config the window
		if (flags & DEPTH_BUFFER)
			SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 32 - (flags & STENCIL_BUFFER) ? 8 : 0);
		
		if (flags & STENCIL_BUFFER)
			SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
		
		sdlWindow = SDL_CreateWindow ("Test", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, SDL_WINDOW_OPENGL);
		
	}
	
	
	SDLWindow::~SDLWindow () {
		
		
		
	}
	
	
	Window* CreateWindow (Application* application, int width, int height, int flags) {
		
		return new SDLWindow (application, width, height, flags);
		
	}
	
	
}