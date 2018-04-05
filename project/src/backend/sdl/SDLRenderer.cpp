#include "SDLApplication.h"
#include "SDLWindow.h"
#include "SDLRenderer.h"
// #include "SDL_syswm.h"
#include "../../graphics/opengl/OpenGL.h"
#include "../../graphics/opengl/OpenGLBindings.h"


namespace lime {
	
	
	SDLRenderer::SDLRenderer (Window* window) {
		
		currentWindow = window;
		sdlWindow = ((SDLWindow*)window)->sdlWindow;
		sdlTexture = 0;
		sdlRenderer = 0;
		context = 0;
		
		width = 0;
		height = 0;
		
		int sdlFlags = 0;
		
		if (window->flags & WINDOW_FLAG_HARDWARE) {
			
			sdlFlags |= SDL_RENDERER_ACCELERATED;
			
			// if (window->flags & WINDOW_FLAG_VSYNC) {
				
			// 	sdlFlags |= SDL_RENDERER_PRESENTVSYNC;
				
			// }
			
			// sdlRenderer = SDL_CreateRenderer (sdlWindow, -1, sdlFlags);
			
			// if (sdlRenderer) {
				
			// 	context = SDL_GL_GetCurrentContext ();
				
			// }
			
			context = SDL_GL_CreateContext (sdlWindow);
			
			if (context) {
				
				if (window->flags & WINDOW_FLAG_VSYNC) {
					
					SDL_GL_SetSwapInterval (1);
					
				} else {
					
					SDL_GL_SetSwapInterval (0);
					
				}
				
				OpenGLBindings::Init ();
				
				#ifndef LIME_GLES
				
				int version = 0;
				glGetIntegerv (GL_MAJOR_VERSION, &version);
				
				if (version == 0) {
					
					float versionScan = 0;
					sscanf ((const char*)glGetString (GL_VERSION), "%f", &versionScan);
					version = versionScan;
					
				}
				
				if (version < 2 && !strstr ((const char*)glGetString (GL_VERSION), "OpenGL ES")) {
					
					SDL_GL_DeleteContext (context);
					context = 0;
					
				}
				
				#elif defined(IPHONE) || defined(APPLETV)
				
				// SDL_SysWMinfo windowInfo;
				// SDL_GetWindowWMInfo (sdlWindow, &windowInfo);
				// OpenGLBindings::defaultFramebuffer = windowInfo.info.uikit.framebuffer;
				// OpenGLBindings::defaultRenderbuffer = windowInfo.info.uikit.colorbuffer;
				glGetIntegerv (GL_FRAMEBUFFER_BINDING, &OpenGLBindings::defaultFramebuffer);
				glGetIntegerv (GL_RENDERBUFFER_BINDING, &OpenGLBindings::defaultRenderbuffer);
				
				#endif
				
			}
			
		}
		
		if (!context) {
			
			sdlFlags &= ~SDL_RENDERER_ACCELERATED;
			sdlFlags &= ~SDL_RENDERER_PRESENTVSYNC;
			
			sdlFlags |= SDL_RENDERER_SOFTWARE;
			
			sdlRenderer = SDL_CreateRenderer (sdlWindow, -1, sdlFlags);
			
		}
		
		if (context || sdlRenderer) {
			
			((SDLApplication*)currentWindow->currentApplication)->RegisterWindow ((SDLWindow*)currentWindow);
			
		} else {
			
			printf ("Could not create SDL renderer: %s.\n", SDL_GetError ());
			
		}
		
	}
	
	
	SDLRenderer::~SDLRenderer () {
		
		if (sdlRenderer) {
			
			SDL_DestroyRenderer (sdlRenderer);
			
		} else if (context) {
			
			SDL_GL_DeleteContext (context);
			
		}
		
	}
	
	
	void SDLRenderer::Flip () {
		
		if (context && !sdlRenderer) {
			
			SDL_GL_SwapWindow (sdlWindow);
			
		} else if (sdlRenderer) {
			
			SDL_RenderPresent (sdlRenderer);
			
		}
		
	}
	
	
	void* SDLRenderer::GetContext () {
		
		return context;
		
	}
	
	
	double SDLRenderer::GetScale () {
		
		if (sdlRenderer) {
			
			int outputWidth;
			int outputHeight;
			
			SDL_GetRendererOutputSize (sdlRenderer, &outputWidth, &outputHeight);
			
			int width;
			int height;
			
			SDL_GetWindowSize (sdlWindow, &width, &height);
			
			double scale = double (outputWidth) / width;
			return scale;
			
		} else if (context) {
			
			int outputWidth;
			int outputHeight;
			
			SDL_GL_GetDrawableSize (sdlWindow, &outputWidth, &outputHeight);
			
			int width;
			int height;
			
			SDL_GetWindowSize (sdlWindow, &width, &height);
			
			double scale = double (outputWidth) / width;
			return scale;
			
		}
		
		return 1;
		
	}
	
	
	value SDLRenderer::Lock () {
		
		if (sdlRenderer) {
			
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
			
		} else {
			
			return alloc_null ();
			
		}
		
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
			
		} else if (context) {
			
			// TODO
			
		}
		
	}
	
	
	const char* SDLRenderer::Type () {
		
		if (context) {
			
			return "opengl";
			
		} else if (sdlRenderer) {
			
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