#include "SDLWindow.h"
#include "SDLApplication.h"

#ifdef HX_WINDOWS
#include <SDL_syswm.h>
#include <Windows.h>
#undef CreateWindow
#endif


namespace lime {
	
	
	SDLWindow::SDLWindow (Application* application, int width, int height, int flags, const char* title) {
		
		currentApplication = application;
		this->flags = flags;
		
		int sdlFlags = 0;
		
		if (flags & WINDOW_FLAG_FULLSCREEN) sdlFlags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
		if (flags & WINDOW_FLAG_RESIZABLE) sdlFlags |= SDL_WINDOW_RESIZABLE;
		if (flags & WINDOW_FLAG_BORDERLESS) sdlFlags |= SDL_WINDOW_BORDERLESS;
		
		if (flags & WINDOW_FLAG_HARDWARE) {
			
			sdlFlags |= SDL_WINDOW_OPENGL;
			sdlFlags |= SDL_WINDOW_ALLOW_HIGHDPI;
			
			#if defined (HX_WINDOWS) && defined (NATIVE_TOOLKIT_SDL_ANGLE)
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_MAJOR_VERSION, 2);
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_MINOR_VERSION, 0);
			SDL_SetHint (SDL_HINT_VIDEO_WIN_D3DCOMPILER, "d3dcompiler_47.dll");
			#endif
			
			if (flags & WINDOW_FLAG_DEPTH_BUFFER) {
				
				SDL_GL_SetAttribute (SDL_GL_DEPTH_SIZE, 32 - (flags & WINDOW_FLAG_STENCIL_BUFFER) ? 8 : 0);
				
			}
			
			if (flags & WINDOW_FLAG_STENCIL_BUFFER) {
				
				SDL_GL_SetAttribute (SDL_GL_STENCIL_SIZE, 8);
				
			}
			
			if (flags & WINDOW_FLAG_HW_AA_HIRES) {
				
				SDL_GL_SetAttribute (SDL_GL_MULTISAMPLEBUFFERS, true);
				SDL_GL_SetAttribute (SDL_GL_MULTISAMPLESAMPLES, 4);
				
			} else if (flags & WINDOW_FLAG_HW_AA) {
				
				SDL_GL_SetAttribute (SDL_GL_MULTISAMPLEBUFFERS, true);
				SDL_GL_SetAttribute (SDL_GL_MULTISAMPLESAMPLES, 2);
				
			}
			
		}
		
		sdlWindow = SDL_CreateWindow (title, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, sdlFlags);
		
		if (!sdlWindow) {
			
			printf ("Could not create SDL window: %s.\n", SDL_GetError ());
			
		}
		
		((SDLApplication*)currentApplication)->RegisterWindow (this);
		
		#ifdef HX_WINDOWS
		
		HINSTANCE handle = ::GetModuleHandle (nullptr);
		HICON icon = ::LoadIcon (handle, MAKEINTRESOURCE (1));
		
		if (icon != nullptr) {
			
			SDL_SysWMinfo wminfo;
			SDL_VERSION (&wminfo.version);
			
			if (SDL_GetWindowWMInfo (sdlWindow, &wminfo) == 1) {
				
				HWND hwnd = wminfo.info.win.window;
				::SetClassLong (hwnd, GCL_HICON, reinterpret_cast<LONG>(icon));
				
			}
			
		}
		
		#endif
		
	}
	
	
	SDLWindow::~SDLWindow () {
		
		if (sdlWindow) {
			
			SDL_DestroyWindow (sdlWindow);
			
		}
		
	}
	
	
	void SDLWindow::Close () {
		
		if (sdlWindow) {
			
			SDL_DestroyWindow (sdlWindow);
			
		}
		
	}
	
	
	bool SDLWindow::GetEnableTextEvents () {
		
		return SDL_IsTextInputActive ();
		
	}
	
	
	int SDLWindow::GetHeight () {
		
		int width;
		int height;
		
		SDL_GetWindowSize (sdlWindow, &width, &height);
		
		return height;
		
	}
	
	
	int SDLWindow::GetWidth () {
		
		int width;
		int height;
		
		SDL_GetWindowSize (sdlWindow, &width, &height);
		
		return width;
		
	}
	
	
	int SDLWindow::GetX () {
		
		int x;
		int y;
		
		SDL_GetWindowPosition (sdlWindow, &x, &y);
		
		return x;
		
	}
	
	
	int SDLWindow::GetY () {
		
		int x;
		int y;
		
		SDL_GetWindowPosition (sdlWindow, &x, &y);
		
		return y;
		
	}
	
	
	void SDLWindow::Move (int x, int y) {
		
		SDL_SetWindowPosition (sdlWindow, x, y);
		
	}
	
	
	void SDLWindow::Resize (int width, int height) {
		
		SDL_SetWindowSize (sdlWindow, width, height);
		
	}
	
	
	void SDLWindow::SetEnableTextEvents (bool enabled) {
		
		if (enabled) {
			
			SDL_StartTextInput ();
			
		} else {
			
			SDL_StopTextInput ();
			
		}
		
	}
	
	
	bool SDLWindow::SetFullscreen (bool fullscreen) {
		
		if (fullscreen) {
			
			SDL_SetWindowFullscreen (sdlWindow, SDL_WINDOW_FULLSCREEN_DESKTOP);
			
		} else {
			
			SDL_SetWindowFullscreen (sdlWindow, 0);
			
		}
		
		return fullscreen;
		
	}
	
	
	void SDLWindow::SetIcon (ImageBuffer *imageBuffer) {
		
		SDL_Surface *surface = SDL_CreateRGBSurfaceFrom (imageBuffer->data->Bytes (), imageBuffer->width, imageBuffer->height, imageBuffer->bpp * 8, imageBuffer->width * imageBuffer->bpp, 0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000);
		
		if (surface) {
			
			SDL_SetWindowIcon (sdlWindow, surface);
			SDL_FreeSurface (surface);
			
		}
		
	}
	
	
	bool SDLWindow::SetMinimized (bool minimized) {
		
		if (minimized) {
			
			SDL_MinimizeWindow (sdlWindow);
			
		} else {
			
			SDL_RestoreWindow (sdlWindow);
			
		}
		
		return minimized;
		
	}
	
	
	Window* CreateWindow (Application* application, int width, int height, int flags, const char* title) {
		
		return new SDLWindow (application, width, height, flags, title);
		
	}
	
	
}