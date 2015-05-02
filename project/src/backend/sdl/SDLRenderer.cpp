#include "SDLWindow.h"
#include "SDLRenderer.h"
#include "../../graphics/opengl/OpenGLBindings.h"


namespace lime {
	
	
	SDLRenderer::SDLRenderer (Window* window) {
		
		currentWindow = window;
		sdlWindow = ((SDLWindow*)window)->sdlWindow;
		sdlTexture = 0;
		
		int sdlFlags = 0;
		bool driverFound = false;
		
		if (window->flags & WINDOW_FLAG_HARDWARE) {
			
			sdlFlags |= SDL_RENDERER_ACCELERATED;

			int numDrivers = SDL_GetNumRenderDrivers ();
			for (int i = 0; i < numDrivers; ++i)
			{
				
				SDL_RendererInfo info;
				SDL_GetRenderDriverInfo (i, &info);
				if (strcmp (info.name, "opengl") == 0 || strcmp (info.name, "opengles2") == 0 || strcmp (info.name, "opengles") ==0 )
				{
					
					SDL_SetHint (SDL_HINT_RENDER_DRIVER, info.name);
					driverFound = true;
					break;
					
				}
				
			}
			if (!driverFound)
				printf ("Could not find OpenGL renderer driver");
			
		} else {
			
			sdlFlags |= SDL_RENDERER_SOFTWARE;
			driverFound = true;
			
		}
		
		if (window->flags & WINDOW_FLAG_VSYNC) sdlFlags |= SDL_RENDERER_PRESENTVSYNC;
		
		sdlRenderer = driverFound ? SDL_CreateRenderer (sdlWindow, -1, sdlFlags) : NULL;
		
		if (!sdlRenderer) {
			
			printf ("Could not create SDL renderer: %s.\n", SDL_GetError ());
			
		}
		
		OpenGLBindings::Init ();
		
	}
	
	
	SDLRenderer::~SDLRenderer () {
		
		if (sdlRenderer) {
			
			SDL_DestroyRenderer (sdlRenderer);
			
		}
		
	}
	
	
	void SDLRenderer::Flip () {
		
		SDL_RenderPresent (sdlRenderer);
		
	}
	
	
	value SDLRenderer::Lock () {
		
		int width;
		int height;
		
		SDL_GetRendererOutputSize (sdlRenderer, &width, &height);
		
		if (!sdlTexture) {
			
			sdlTexture = SDL_CreateTexture (sdlRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, width, height);
			
		}
		
		value result = alloc_empty_object ();
		
		void *pixels;
		int pitch;
		
		if (SDL_LockTexture (sdlTexture, NULL, &pixels, &pitch) == 0) {
			
			alloc_field (result, val_id ("width"), alloc_int (width));
			alloc_field (result, val_id ("height"), alloc_int (height));
			alloc_field (result, val_id ("pixels"), alloc_float ((intptr_t)pixels));
			alloc_field (result, val_id ("pitch"), alloc_int (pitch));
			
		}
		
		return result;
		
	}
	
	
	void SDLRenderer::Unlock () {
		
		if (sdlTexture) {
			
			SDL_UnlockTexture (sdlTexture);
			SDL_RenderClear (sdlRenderer);
			SDL_RenderCopy (sdlRenderer, sdlTexture, NULL, NULL);
			
		}
		
	}
	
	
	Renderer* CreateRenderer (Window* window) {
		
		return new SDLRenderer (window);
		
	}
	
	
}