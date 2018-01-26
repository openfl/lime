#include "SDLWindow.h"
#include "SDLRenderer.h"
#include "../../graphics/opengl/OpenGL.h"
#include "../../graphics/opengl/OpenGLBindings.h"


namespace lime {
	
	
	SDLRenderer::SDLRenderer (Window* window) {
		
		currentWindow = window;
		sdlWindow = ((SDLWindow*)window)->sdlWindow;
		sdlTexture = 0;
		context = 0;
		
		width = 0;
		height = 0;
		
		int sdlFlags = 0;
		
		if (window->flags & WINDOW_FLAG_HARDWARE) {
			
			sdlFlags |= SDL_RENDERER_ACCELERATED;
			
			if (window->flags & WINDOW_FLAG_VSYNC) {
				
				sdlFlags |= SDL_RENDERER_PRESENTVSYNC;
				
			}
			
		} else {
			
			sdlFlags |= SDL_RENDERER_SOFTWARE;
			
		}
		
		sdlRenderer = SDL_CreateRenderer (sdlWindow, -1, sdlFlags);
		
		if (sdlFlags & SDL_RENDERER_ACCELERATED) {
			
			if (sdlRenderer) {
				
				bool valid = false;
				context = SDL_GL_GetCurrentContext ();
				
				if (context) {
					
					OpenGLBindings::Init ();
					
					#ifndef LIME_GLES
					int version = 0;
					glGetIntegerv (GL_MAJOR_VERSION, &version);
					
					if (version == 0) {
						
						float versionScan = 0;
						sscanf ((const char*)glGetString (GL_VERSION), "%f", &versionScan);
						version = versionScan;
						
					}
					
					if (version >= 2 || strstr ((const char*)glGetString (GL_VERSION), "OpenGL ES")) {
						
						valid = true;
						
					}
					#else
					valid = true;
					#endif
					
					#ifdef IPHONE
					glGetIntegerv (GL_FRAMEBUFFER_BINDING_OES, &OpenGLBindings::defaultFramebuffer);
					#endif
					
				}
				
				if (!valid) {
					
					SDL_DestroyRenderer (sdlRenderer);
					sdlRenderer = 0;
					
				}
				
			}
			
			if (!sdlRenderer) {
				
				sdlFlags &= ~SDL_RENDERER_ACCELERATED;
				sdlFlags &= ~SDL_RENDERER_PRESENTVSYNC;
				
				sdlFlags |= SDL_RENDERER_SOFTWARE;
				
				sdlRenderer = SDL_CreateRenderer (sdlWindow, -1, sdlFlags);
				
			}
			
		}
		
		if (!sdlRenderer) {
			
			printf ("Could not create SDL renderer: %s.\n", SDL_GetError ());
			
		}
		
	}
	
	
	SDLRenderer::~SDLRenderer () {
		
		if (sdlRenderer) {
			
			SDL_DestroyRenderer (sdlRenderer);
			
		}
		
	}
	
	
	void SDLRenderer::Flip () {
		
		SDL_RenderPresent (sdlRenderer);
		
	}
	
	
	void* SDLRenderer::GetContext () {
		
		return context;
		
	}
	
	
	double SDLRenderer::GetScale () {
		
		int outputWidth;
		int outputHeight;
		
		SDL_GetRendererOutputSize (sdlRenderer, &outputWidth, &outputHeight);
		
		int width;
		int height;
		
		SDL_GetWindowSize (sdlWindow, &width, &height);
		
		double scale = double (outputWidth) / width;
		return scale;
		
	}
	
	
	value SDLRenderer::Lock () {
		
		int width;
		int height;
		
		SDL_GetRendererOutputSize (sdlRenderer, &width, &height);
		
		if (width != this->width || height != this->height) {
			
			if (sdlTexture) {
				
				SDL_DestroyTexture (sdlTexture);
				
			}
			
			sdlTexture = SDL_CreateTexture (sdlRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, width, height);
			
		}
		
		value result = alloc_empty_object ();
		
		void *pixels;
		int pitch;
		
		if (SDL_LockTexture (sdlTexture, NULL, &pixels, &pitch) == 0) {
			
			alloc_field (result, val_id ("width"), alloc_int (width));
			alloc_field (result, val_id ("height"), alloc_int (height));
			alloc_field (result, val_id ("pixels"), alloc_float ((uintptr_t)pixels));
			alloc_field (result, val_id ("pitch"), alloc_int (pitch));
			
		}
		
		return result;
		
	}
	
	
	void SDLRenderer::MakeCurrent () {
		
		if (sdlWindow && context) {
			
			SDL_GL_MakeCurrent (sdlWindow, context);
			
		}
		
	}
	
	
	void SDLRenderer::ReadPixels (ImageBuffer *buffer, Rectangle *rect) {
		
		if (sdlRenderer) {
			
			SDL_Rect bounds = { 0, 0, 0, 0 };
			
			if (rect) {
				
				bounds.x = rect->x;
				bounds.y = rect->y;
				bounds.w = rect->width;
				bounds.h = rect->height;
				
			} else {
				
				SDL_GetWindowSize (sdlWindow, &bounds.w, &bounds.h);
				
			}
			
			buffer->Resize (bounds.w, bounds.h, 32);
			
			SDL_RenderReadPixels (sdlRenderer, &bounds, SDL_PIXELFORMAT_ABGR8888, buffer->data->Data (), buffer->Stride ());
			
		}
		
	}
	
	
	const char* SDLRenderer::Type () {
		
		if (sdlRenderer) {
			
			SDL_RendererInfo info;
			SDL_GetRendererInfo (sdlRenderer, &info);
			
			if (info.flags & SDL_RENDERER_SOFTWARE) {
				
				return "software";
				
			} else {
				
				return "opengl";
				
			}
			
		}
		
		return "none";
		
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