#include "SDLWindow.h"
#include "SDLCursor.h"
#include "SDLApplication.h"
#include "../../graphics/opengl/OpenGL.h"
#include "../../graphics/opengl/OpenGLBindings.h"

#ifdef HX_WINDOWS
#include <SDL_syswm.h>
#include <Windows.h>
#undef CreateWindow
#endif


namespace lime {


	static Cursor currentCursor = DEFAULT;

	SDL_Cursor* SDLCursor::arrowCursor = 0;
	SDL_Cursor* SDLCursor::crosshairCursor = 0;
	SDL_Cursor* SDLCursor::moveCursor = 0;
	SDL_Cursor* SDLCursor::pointerCursor = 0;
	SDL_Cursor* SDLCursor::resizeNESWCursor = 0;
	SDL_Cursor* SDLCursor::resizeNSCursor = 0;
	SDL_Cursor* SDLCursor::resizeNWSECursor = 0;
	SDL_Cursor* SDLCursor::resizeWECursor = 0;
	SDL_Cursor* SDLCursor::textCursor = 0;
	SDL_Cursor* SDLCursor::waitCursor = 0;
	SDL_Cursor* SDLCursor::waitArrowCursor = 0;

	static bool displayModeSet = false;


	SDLWindow::SDLWindow (Application* application, int width, int height, int flags, const char* title) {

		sdlTexture = 0;
		sdlRenderer = 0;
		context = 0;

		contextWidth = 0;
		contextHeight = 0;

		currentApplication = application;
		this->flags = flags;

		int sdlWindowFlags = 0;

		if (flags & WINDOW_FLAG_FULLSCREEN) sdlWindowFlags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
		if (flags & WINDOW_FLAG_RESIZABLE) sdlWindowFlags |= SDL_WINDOW_RESIZABLE;
		if (flags & WINDOW_FLAG_BORDERLESS) sdlWindowFlags |= SDL_WINDOW_BORDERLESS;
		if (flags & WINDOW_FLAG_HIDDEN) sdlWindowFlags |= SDL_WINDOW_HIDDEN;
		if (flags & WINDOW_FLAG_MINIMIZED) sdlWindowFlags |= SDL_WINDOW_MINIMIZED;
		if (flags & WINDOW_FLAG_MAXIMIZED) sdlWindowFlags |= SDL_WINDOW_MAXIMIZED;

		#ifndef EMSCRIPTEN
		if (flags & WINDOW_FLAG_ALWAYS_ON_TOP) sdlWindowFlags |= SDL_WINDOW_ALWAYS_ON_TOP;
		#endif

		#if defined (HX_WINDOWS) && defined (NATIVE_TOOLKIT_SDL_ANGLE) && !defined (HX_WINRT)
		OSVERSIONINFOEXW osvi = { sizeof (osvi), 0, 0, 0, 0, {0}, 0, 0 };
		DWORDLONG const dwlConditionMask = VerSetConditionMask (VerSetConditionMask (VerSetConditionMask (0, VER_MAJORVERSION, VER_GREATER_EQUAL), VER_MINORVERSION, VER_GREATER_EQUAL), VER_SERVICEPACKMAJOR, VER_GREATER_EQUAL);
		osvi.dwMajorVersion = HIBYTE (_WIN32_WINNT_VISTA);
		osvi.dwMinorVersion = LOBYTE (_WIN32_WINNT_VISTA);
		osvi.wServicePackMajor = 0;

		if (VerifyVersionInfoW (&osvi, VER_MAJORVERSION | VER_MINORVERSION | VER_SERVICEPACKMAJOR, dwlConditionMask) == FALSE) {

			flags &= ~WINDOW_FLAG_HARDWARE;

		}
		#endif

		#if !defined(EMSCRIPTEN) && !defined(LIME_SWITCH)
		SDL_SetHint (SDL_HINT_ANDROID_TRAP_BACK_BUTTON, "0");
		SDL_SetHint (SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "1");
		SDL_SetHint (SDL_HINT_MOUSE_TOUCH_EVENTS, "0");
		SDL_SetHint (SDL_HINT_TOUCH_MOUSE_EVENTS, "1");
		#endif

		if (flags & WINDOW_FLAG_HARDWARE) {

			sdlWindowFlags |= SDL_WINDOW_OPENGL;

			if (flags & WINDOW_FLAG_ALLOW_HIGHDPI) {

				sdlWindowFlags |= SDL_WINDOW_ALLOW_HIGHDPI;

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

			#if defined (IPHONE) || defined (APPLETV)
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_MAJOR_VERSION, 3);
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

			if (flags & WINDOW_FLAG_COLOR_DEPTH_32_BIT) {

				SDL_GL_SetAttribute (SDL_GL_RED_SIZE, 8);
				SDL_GL_SetAttribute (SDL_GL_GREEN_SIZE, 8);
				SDL_GL_SetAttribute (SDL_GL_BLUE_SIZE, 8);
				SDL_GL_SetAttribute (SDL_GL_ALPHA_SIZE, 8);

			} else {

				SDL_GL_SetAttribute (SDL_GL_RED_SIZE, 5);
				SDL_GL_SetAttribute (SDL_GL_GREEN_SIZE, 6);
				SDL_GL_SetAttribute (SDL_GL_BLUE_SIZE, 5);

			}

		}

		sdlWindow = SDL_CreateWindow (title, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, sdlWindowFlags);

		#if defined (IPHONE) || defined (APPLETV)
		if (sdlWindow && !SDL_GL_CreateContext (sdlWindow)) {

			SDL_DestroyWindow (sdlWindow);
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_MAJOR_VERSION, 2);

			sdlWindow = SDL_CreateWindow (title, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, sdlWindowFlags);

		}
		#endif

		if (!sdlWindow) {

			printf ("Could not create SDL window: %s.\n", SDL_GetError ());
			return;

		}

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)

		HINSTANCE handle = ::GetModuleHandle (nullptr);
		HICON icon = ::LoadIcon (handle, MAKEINTRESOURCE (1));

		if (icon != nullptr) {

			SDL_SysWMinfo wminfo;
			SDL_VERSION (&wminfo.version);

			if (SDL_GetWindowWMInfo (sdlWindow, &wminfo) == 1) {

				HWND hwnd = wminfo.info.win.window;

				#ifdef _WIN64
				::SetClassLongPtr (hwnd, GCLP_HICON, reinterpret_cast<LONG_PTR>(icon));
				#else
				::SetClassLong (hwnd, GCL_HICON, reinterpret_cast<LONG>(icon));
				#endif

			}

		}

		#endif

		int sdlRendererFlags = 0;

		if (flags & WINDOW_FLAG_HARDWARE) {

			sdlRendererFlags |= SDL_RENDERER_ACCELERATED;

			// if (window->flags & WINDOW_FLAG_VSYNC) {

			#ifdef EMSCRIPTEN
			sdlRendererFlags |= SDL_RENDERER_PRESENTVSYNC;
			#endif

			// }

			// sdlRenderer = SDL_CreateRenderer (sdlWindow, -1, sdlRendererFlags);

			// if (sdlRenderer) {

			// 	context = SDL_GL_GetCurrentContext ();

			// }

			context = SDL_GL_CreateContext (sdlWindow);

			if (context && SDL_GL_MakeCurrent (sdlWindow, context) == 0) {

				if (flags & WINDOW_FLAG_VSYNC) {

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

			} else {

				SDL_GL_DeleteContext (context);
				context = NULL;

			}

		}

		if (!context) {

			sdlRendererFlags &= ~SDL_RENDERER_ACCELERATED;
			sdlRendererFlags &= ~SDL_RENDERER_PRESENTVSYNC;

			sdlRendererFlags |= SDL_RENDERER_SOFTWARE;

			sdlRenderer = SDL_CreateRenderer (sdlWindow, -1, sdlRendererFlags);

		}

		if (context || sdlRenderer) {

			((SDLApplication*)currentApplication)->RegisterWindow (this);

		} else {

			printf ("Could not create SDL renderer: %s.\n", SDL_GetError ());

		}

	}


	SDLWindow::~SDLWindow () {

		if (sdlWindow) {

			SDL_DestroyWindow (sdlWindow);
			sdlWindow = 0;

		}

		if (sdlRenderer) {

			SDL_DestroyRenderer (sdlRenderer);

		} else if (context) {

			SDL_GL_DeleteContext (context);

		}

	}


	void SDLWindow::Alert (const char* message, const char* title) {

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)

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
			sdlWindow = 0;

		}

	}


	bool SDLWindow::SetVisible (bool visible) {

		if (visible) {

			SDL_ShowWindow (sdlWindow);

		} else {

			SDL_HideWindow (sdlWindow);

		}

		return (SDL_GetWindowFlags (sdlWindow) & SDL_WINDOW_SHOWN);

	}


	void SDLWindow::ContextFlip () {

		if (context && !sdlRenderer) {

			SDL_GL_SwapWindow (sdlWindow);

		} else if (sdlRenderer) {

			SDL_RenderPresent (sdlRenderer);

		}

	}


	void* SDLWindow::ContextLock (bool useCFFIValue) {

		if (sdlRenderer) {

			int width;
			int height;

			SDL_GetRendererOutputSize (sdlRenderer, &width, &height);

			if (width != contextWidth || height != contextHeight) {

				if (sdlTexture) {

					SDL_DestroyTexture (sdlTexture);

				}

				sdlTexture = SDL_CreateTexture (sdlRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, width, height);

				contextWidth = width;
				contextHeight = height;

			}

			void *pixels;
			int pitch;

			if (useCFFIValue) {

				if (SDL_LockTexture (sdlTexture, NULL, &pixels, &pitch) == 0) {

					value result = alloc_empty_object ();
					alloc_field (result, val_id ("width"), alloc_int (contextWidth));
					alloc_field (result, val_id ("height"), alloc_int (contextHeight));
					alloc_field (result, val_id ("pixels"), alloc_float ((uintptr_t)pixels));
					alloc_field (result, val_id ("pitch"), alloc_int (pitch));
					return result;

				} else {

					return alloc_null ();

				}

			} else {

				const int id_width = hl_hash_utf8 ("width");
				const int id_height = hl_hash_utf8 ("height");
				const int id_pixels = hl_hash_utf8 ("pixels");
				const int id_pitch = hl_hash_utf8 ("pitch");

				if (SDL_LockTexture (sdlTexture, NULL, &pixels, &pitch) == 0) {

					vdynamic* result = (vdynamic*)hl_alloc_dynobj();
					hl_dyn_seti (result, id_width, &hlt_i32, contextWidth);
					hl_dyn_seti (result, id_height, &hlt_i32, contextHeight);
					hl_dyn_setd (result, id_pixels, (uintptr_t)pixels);
					hl_dyn_seti (result, id_pitch, &hlt_i32, pitch);
					return result;

				} else {

					return 0;

				}

			}

		} else {

			if (useCFFIValue) {

				return alloc_null ();

			} else {

				return 0;

			}

		}

	}


	void SDLWindow::ContextMakeCurrent () {

		if (sdlWindow && context) {

			SDL_GL_MakeCurrent (sdlWindow, context);

		}

	}


	void SDLWindow::ContextUnlock () {

		if (sdlTexture) {

			SDL_UnlockTexture (sdlTexture);
			SDL_RenderClear (sdlRenderer);
			SDL_RenderCopy (sdlRenderer, sdlTexture, NULL, NULL);

		}

	}


	void SDLWindow::Focus () {

		SDL_RaiseWindow (sdlWindow);

	}


	void* SDLWindow::GetContext () {

		return context;

	}


	const char* SDLWindow::GetContextType () {

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


	int SDLWindow::GetDisplay () {

		return SDL_GetWindowDisplayIndex (sdlWindow);

	}


	void SDLWindow::GetDisplayMode (DisplayMode* displayMode) {

		SDL_DisplayMode mode;
		SDL_GetWindowDisplayMode (sdlWindow, &mode);

		displayMode->width = mode.w;
		displayMode->height = mode.h;

		switch (mode.format) {

			case SDL_PIXELFORMAT_ARGB8888:

				displayMode->pixelFormat = ARGB32;
				break;

			case SDL_PIXELFORMAT_BGRA8888:
			case SDL_PIXELFORMAT_BGRX8888:

				displayMode->pixelFormat = BGRA32;
				break;

			default:

				displayMode->pixelFormat = RGBA32;

		}

		displayMode->refreshRate = mode.refresh_rate;

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


	bool SDLWindow::GetMouseLock () {

		return SDL_GetRelativeMouseMode ();

	}


	float SDLWindow::GetOpacity () {

		float opacity = 1.0f;

		SDL_GetWindowOpacity (sdlWindow, &opacity);

		return opacity;

	}


	double SDLWindow::GetScale () {

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


	bool SDLWindow::GetTextInputEnabled () {

		return SDL_IsTextInputActive ();

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


	void SDLWindow::ReadPixels (ImageBuffer *buffer, Rectangle *rect) {

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

			SDL_RenderReadPixels (sdlRenderer, &bounds, SDL_PIXELFORMAT_ABGR8888, buffer->data->buffer->b, buffer->Stride ());

		} else if (context) {

			// TODO

		}

	}


	void SDLWindow::Resize (int width, int height) {

		SDL_SetWindowSize (sdlWindow, width, height);

	}


	void SDLWindow::SetMinimumSize (int width, int height) {

		SDL_SetWindowMinimumSize (sdlWindow, width, height);

	}


	void SDLWindow::SetMaximumSize (int width, int height) {

		SDL_SetWindowMaximumSize (sdlWindow, width, height);

	}


	bool SDLWindow::SetBorderless (bool borderless) {

		if (borderless) {

			SDL_SetWindowBordered (sdlWindow, SDL_FALSE);

		} else {

			SDL_SetWindowBordered (sdlWindow, SDL_TRUE);

		}

		return borderless;

	}


	void SDLWindow::SetCursor (Cursor cursor) {

		if (cursor != currentCursor) {

			if (currentCursor == HIDDEN) {

				SDL_ShowCursor (SDL_ENABLE);

			}

			switch (cursor) {

				case HIDDEN:

					SDL_ShowCursor (SDL_DISABLE);

				case CROSSHAIR:

					if (!SDLCursor::crosshairCursor) {

						SDLCursor::crosshairCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_CROSSHAIR);

					}

					SDL_SetCursor (SDLCursor::crosshairCursor);
					break;

				case MOVE:

					if (!SDLCursor::moveCursor) {

						SDLCursor::moveCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_SIZEALL);

					}

					SDL_SetCursor (SDLCursor::moveCursor);
					break;

				case POINTER:

					if (!SDLCursor::pointerCursor) {

						SDLCursor::pointerCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_HAND);

					}

					SDL_SetCursor (SDLCursor::pointerCursor);
					break;

				case RESIZE_NESW:

					if (!SDLCursor::resizeNESWCursor) {

						SDLCursor::resizeNESWCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_SIZENESW);

					}

					SDL_SetCursor (SDLCursor::resizeNESWCursor);
					break;

				case RESIZE_NS:

					if (!SDLCursor::resizeNSCursor) {

						SDLCursor::resizeNSCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_SIZENS);

					}

					SDL_SetCursor (SDLCursor::resizeNSCursor);
					break;

				case RESIZE_NWSE:

					if (!SDLCursor::resizeNWSECursor) {

						SDLCursor::resizeNWSECursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_SIZENWSE);

					}

					SDL_SetCursor (SDLCursor::resizeNWSECursor);
					break;

				case RESIZE_WE:

					if (!SDLCursor::resizeWECursor) {

						SDLCursor::resizeWECursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_SIZEWE);

					}

					SDL_SetCursor (SDLCursor::resizeWECursor);
					break;

				case TEXT:

					if (!SDLCursor::textCursor) {

						SDLCursor::textCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_IBEAM);

					}

					SDL_SetCursor (SDLCursor::textCursor);
					break;

				case WAIT:

					if (!SDLCursor::waitCursor) {

						SDLCursor::waitCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_WAIT);

					}

					SDL_SetCursor (SDLCursor::waitCursor);
					break;

				case WAIT_ARROW:

					if (!SDLCursor::waitArrowCursor) {

						SDLCursor::waitArrowCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_WAITARROW);

					}

					SDL_SetCursor (SDLCursor::waitArrowCursor);
					break;

				default:

					if (!SDLCursor::arrowCursor) {

						SDLCursor::arrowCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_ARROW);

					}

					SDL_SetCursor (SDLCursor::arrowCursor);
					break;

			}

			currentCursor = cursor;

		}

	}


	void SDLWindow::SetDisplayMode (DisplayMode* displayMode) {

		Uint32 pixelFormat = 0;

		switch (displayMode->pixelFormat) {

			case ARGB32:

				pixelFormat = SDL_PIXELFORMAT_ARGB8888;
				break;

			case BGRA32:

				pixelFormat = SDL_PIXELFORMAT_BGRA8888;
				break;

			default:

				pixelFormat = SDL_PIXELFORMAT_RGBA8888;

		}

		SDL_DisplayMode mode = { pixelFormat, displayMode->width, displayMode->height, displayMode->refreshRate, 0 };

		if (SDL_SetWindowDisplayMode (sdlWindow, &mode) == 0) {

			displayModeSet = true;

			if (SDL_GetWindowFlags (sdlWindow) & SDL_WINDOW_FULLSCREEN_DESKTOP) {

				SDL_SetWindowFullscreen (sdlWindow, SDL_WINDOW_FULLSCREEN);

			}

		}

	}


	bool SDLWindow::SetFullscreen (bool fullscreen) {

		if (fullscreen) {

			if (displayModeSet) {

				SDL_SetWindowFullscreen (sdlWindow, SDL_WINDOW_FULLSCREEN);

			} else {

				SDL_SetWindowFullscreen (sdlWindow, SDL_WINDOW_FULLSCREEN_DESKTOP);

			}

		} else {

			SDL_SetWindowFullscreen (sdlWindow, 0);

		}

		return fullscreen;

	}


	void SDLWindow::SetIcon (ImageBuffer *imageBuffer) {

		SDL_Surface *surface = SDL_CreateRGBSurfaceFrom (imageBuffer->data->buffer->b, imageBuffer->width, imageBuffer->height, imageBuffer->bitsPerPixel, imageBuffer->Stride (), 0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000);

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


	void SDLWindow::SetMouseLock (bool mouseLock) {

		if (mouseLock) {

			SDL_SetRelativeMouseMode (SDL_TRUE);

		} else {

			SDL_SetRelativeMouseMode (SDL_FALSE);

		}

	}


	void SDLWindow::SetOpacity (float opacity) {

		SDL_SetWindowOpacity (sdlWindow, opacity);

	}


	bool SDLWindow::SetResizable (bool resizable) {

		#ifndef EMSCRIPTEN

		if (resizable) {

			SDL_SetWindowResizable (sdlWindow, SDL_TRUE);

		} else {

			SDL_SetWindowResizable (sdlWindow, SDL_FALSE);

		}

		return (SDL_GetWindowFlags (sdlWindow) & SDL_WINDOW_RESIZABLE);

		#else

		return resizable;

		#endif

	}


	void SDLWindow::SetTextInputEnabled (bool enabled) {

		if (enabled) {

			SDL_StartTextInput ();

		} else {

			SDL_StopTextInput ();

		}

	}


	void SDLWindow::SetTextInputRect (Rectangle * rect) {

		SDL_Rect bounds = { 0, 0, 0, 0 };

		if (rect) {

			bounds.x = rect->x;
			bounds.y = rect->y;
			bounds.w = rect->width;
			bounds.h = rect->height;

		}

		SDL_SetTextInputRect(&bounds);
	}


	const char* SDLWindow::SetTitle (const char* title) {

		SDL_SetWindowTitle (sdlWindow, title);

		return title;

	}


	void SDLWindow::WarpMouse (int x, int y) {

		SDL_WarpMouseInWindow (sdlWindow, x, y);

	}


	Window* CreateWindow (Application* application, int width, int height, int flags, const char* title) {

		return new SDLWindow (application, width, height, flags, title);

	}


}
