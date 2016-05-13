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
		
		#if defined (HX_WINDOWS) && defined (NATIVE_TOOLKIT_SDL_ANGLE)
		OSVERSIONINFOEXW osvi = { sizeof (osvi), 0, 0, 0, 0, {0}, 0, 0 };
		DWORDLONG const dwlConditionMask = VerSetConditionMask (VerSetConditionMask (VerSetConditionMask (0, VER_MAJORVERSION, VER_GREATER_EQUAL), VER_MINORVERSION, VER_GREATER_EQUAL), VER_SERVICEPACKMAJOR, VER_GREATER_EQUAL);
		osvi.dwMajorVersion = HIBYTE (_WIN32_WINNT_VISTA);
		osvi.dwMinorVersion = LOBYTE (_WIN32_WINNT_VISTA);
		osvi.wServicePackMajor = 0;
		
		if (VerifyVersionInfoW (&osvi, VER_MAJORVERSION | VER_MINORVERSION | VER_SERVICEPACKMAJOR, dwlConditionMask) == FALSE) {
			
			flags &= ~WINDOW_FLAG_HARDWARE;
			
		}
		#endif
		
		if (flags & WINDOW_FLAG_HARDWARE) {
			
			sdlFlags |= SDL_WINDOW_OPENGL;
			
			if (flags & WINDOW_FLAG_ALLOW_HIGHDPI) {
				
				sdlFlags |= SDL_WINDOW_ALLOW_HIGHDPI;
				
			}
			
			#if defined (HX_WINDOWS) && defined (NATIVE_TOOLKIT_SDL_ANGLE)
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_MAJOR_VERSION, 2);
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_MINOR_VERSION, 0);
			SDL_SetHint (SDL_HINT_VIDEO_WIN_D3DCOMPILER, "d3dcompiler_47.dll");
			#endif
			
			#if defined (RASPBERRYPI)
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_MAJOR_VERSION, 2);
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_MINOR_VERSION, 0);
			SDL_SetHint (SDL_HINT_RENDER_DRIVER, "opengles2");
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
			
			SDL_GL_SetAttribute (SDL_GL_RED_SIZE, 5);
			SDL_GL_SetAttribute (SDL_GL_GREEN_SIZE, 6);
			SDL_GL_SetAttribute (SDL_GL_BLUE_SIZE, 5);
			
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
	
	
	void SDLWindow::Alert (const char* message, const char* title) {
		
		#ifdef HX_WINDOWS
		
		int count = 0;
		int speed = 0;
		bool stopOnForeground = true;
		
		SDL_SysWMinfo info;
		SDL_VERSION (&info.version);
		SDL_GetWindowWMInfo (sdlWindow, &info);
		
		FLASHWINFO fi;
		fi.cbSize = sizeof (FLASHWINFO);
		fi.hwnd = info.info.win.window;
		fi.dwFlags = stopOnForeground ? FLASHW_ALL | FLASHW_TIMERNOFG : FLASHW_ALL | FLASHW_TIMER;
		fi.uCount = count;
		fi.dwTimeout = speed;
		FlashWindowEx (&fi);
		
		#endif
		
		if (message) {
			
			SDL_ShowSimpleMessageBox (SDL_MESSAGEBOX_INFORMATION, title, message, sdlWindow);
			
		}
		
	}
	
	
	void SDLWindow::Close () {
		
		if (sdlWindow) {
			
			SDL_DestroyWindow (sdlWindow);
			
		}
		
	}
	
	
	void SDLWindow::Focus () {
		
		SDL_RaiseWindow (sdlWindow);
		
	}
	
	
	int SDLWindow::GetDisplay () {
		
		return SDL_GetWindowDisplayIndex (sdlWindow);
		
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
	
	
	uint32_t SDLWindow::GetID () {
		
		return SDL_GetWindowID (sdlWindow);
		
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
	
	
	bool SDLWindow::SetBorderless (bool borderless) {
		
		if (borderless) {
			
			SDL_SetWindowBordered (sdlWindow, SDL_FALSE);
			
		} else {
			
			SDL_SetWindowBordered (sdlWindow, SDL_TRUE);
			
		}
		
		return borderless;
		
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
		
		SDL_Surface *surface = SDL_CreateRGBSurfaceFrom (imageBuffer->data->Data (), imageBuffer->width, imageBuffer->height, imageBuffer->bitsPerPixel, imageBuffer->Stride (), 0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000);
		
		if (surface) {
			
			SDL_SetWindowIcon (sdlWindow, surface);
			SDL_FreeSurface (surface);
			
		}
		
	}
	
	
	bool SDLWindow::SetMaximized (bool maximized) {
		
		if (maximized) {
			
			SDL_MaximizeWindow (sdlWindow);
			
		} else {
			
			SDL_RestoreWindow (sdlWindow);
			
		}
		
		return maximized;
		
	}
	
	
	bool SDLWindow::SetMinimized (bool minimized) {
		
		if (minimized) {
			
			SDL_MinimizeWindow (sdlWindow);
			
		} else {
			
			SDL_RestoreWindow (sdlWindow);
			
		}
		
		return minimized;
		
	}
	
	
	bool SDLWindow::SetResizable (bool resizable) {
		
		#if defined(HX_WINDOWS)
		
		SDL_SysWMinfo info;
		SDL_VERSION (&info.version);
		SDL_GetWindowWMInfo (sdlWindow, &info);
		
		HWND hwnd = info.info.win.window;
		DWORD style = GetWindowLong (hwnd, GWL_STYLE);
		
		if (resizable) {
			
			style |= WS_THICKFRAME;
			
		} else {
			
			style &= ~WS_THICKFRAME;
			
		}
		
		SetWindowLong (hwnd, GWL_STYLE, style);
		
		#elif defined(HX_MACOS)
		
		//TODO
		//consider: http://stackoverflow.com/questions/10473700/set-window-resizable/10473949#10473949
		
		#elif defined(HX_LINUX)
		
		//TODO
		//maybe something in here? https://tronche.com/gui/x/xlib/ICC/client-to-window-manager/wm-normal-hints.html
		
		#endif
		
		return resizable;
		
	}
	
	
	const char* SDLWindow::SetTitle (const char* title) {
		
		SDL_SetWindowTitle (sdlWindow, title);
		
		return title;
		
	}
	
	
	Window* CreateWindow (Application* application, int width, int height, int flags, const char* title) {
		
		return new SDLWindow (application, width, height, flags, title);
		
	}
	
	
}
