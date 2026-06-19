#include "SDLWindow.h"
#include "SDLCursor.h"
#include "SDLApplication.h"
#include "../../graphics/opengl/OpenGL.h"
#include "../../graphics/opengl/OpenGLBindings.h"

#ifdef HX_WINDOWS
#include <SDL3/SDL_properties.h>
#include <windows.h>
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

#if defined (HX_WINDOWS) && !defined (HX_WINRT)
	static const wchar_t* LIME_SDL_OLD_RESIZE_WNDPROC_PROP = L"LimeSDL.OldResizeWndProc";
	static const wchar_t* LIME_SDL_WINDOW_ID_PROP = L"LimeSDL.WindowID";
	static const wchar_t* LIME_SDL_LAST_RESIZE_WIDTH_PROP = L"LimeSDL.LastResizeWidth";
	static const wchar_t* LIME_SDL_LAST_RESIZE_HEIGHT_PROP = L"LimeSDL.LastResizeHeight";
	static const wchar_t* LIME_SDL_LAST_RESIZE_TICK_PROP = L"LimeSDL.LastResizeTick";
	static const Uint32 LIME_SDL_MIN_RESIZE_PUSH_INTERVAL_MS = 8;

	static HWND GetWin32Window (SDL_Window* sdlWindow) {

		if (!sdlWindow) return NULL;
		return (HWND)SDL_GetPointerProperty (SDL_GetWindowProperties (sdlWindow), SDL_PROP_WINDOW_WIN32_HWND_POINTER, NULL);

	}

	static bool ShouldQueueLiveResizeEvent (HWND hwnd, int width, int height, bool throttled) {

		if (width < 1 || height < 1) return false;

		int lastWidth = (int)(INT_PTR)GetPropW (hwnd, LIME_SDL_LAST_RESIZE_WIDTH_PROP);
		int lastHeight = (int)(INT_PTR)GetPropW (hwnd, LIME_SDL_LAST_RESIZE_HEIGHT_PROP);
		if (width == lastWidth && height == lastHeight) return false;

		Uint32 now = SDL_GetTicks ();
		if (throttled) {

			Uint32 lastTick = (Uint32)(UINT_PTR)GetPropW (hwnd, LIME_SDL_LAST_RESIZE_TICK_PROP);
			if (lastTick != 0 && (Uint32)(now - lastTick) < LIME_SDL_MIN_RESIZE_PUSH_INTERVAL_MS) {

				return false;

			}

		}

		SetPropW (hwnd, LIME_SDL_LAST_RESIZE_WIDTH_PROP, (HANDLE)(INT_PTR)width);
		SetPropW (hwnd, LIME_SDL_LAST_RESIZE_HEIGHT_PROP, (HANDLE)(INT_PTR)height);
		SetPropW (hwnd, LIME_SDL_LAST_RESIZE_TICK_PROP, (HANDLE)(UINT_PTR)now);
		return true;

	}

	static void PushLiveResizeEvent (HWND hwnd, int width, int height, bool throttled) {

		if (!ShouldQueueLiveResizeEvent (hwnd, width, height, throttled)) return;

		Uint32 windowID = (Uint32)(UINT_PTR)GetPropW (hwnd, LIME_SDL_WINDOW_ID_PROP);
		if (!windowID) return;

		SDL_Event event;
		SDL_zero (event);
		event.type = SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED;
		event.window.windowID = windowID;
		event.window.data1 = width;
		event.window.data2 = height;
		SDL_PushEvent (&event);

	}

	static void PushLiveResizeEventFromRect (HWND hwnd, const RECT* windowRect) {

		if (!windowRect) return;

		RECT currentWindowRect;
		RECT currentClientRect;
		if (!GetWindowRect (hwnd, &currentWindowRect)) return;
		if (!GetClientRect (hwnd, &currentClientRect)) return;

		POINT currentClientTopLeft = { currentClientRect.left, currentClientRect.top };
		POINT currentClientBottomRight = { currentClientRect.right, currentClientRect.bottom };
		if (!ClientToScreen (hwnd, &currentClientTopLeft) || !ClientToScreen (hwnd, &currentClientBottomRight)) return;

		int nonClientWidth = (currentWindowRect.right - currentWindowRect.left) - (currentClientBottomRight.x - currentClientTopLeft.x);
		int nonClientHeight = (currentWindowRect.bottom - currentWindowRect.top) - (currentClientBottomRight.y - currentClientTopLeft.y);
		if (nonClientWidth < 0) nonClientWidth = 0;
		if (nonClientHeight < 0) nonClientHeight = 0;

		int width = (windowRect->right - windowRect->left) - nonClientWidth;
		int height = (windowRect->bottom - windowRect->top) - nonClientHeight;
		PushLiveResizeEvent (hwnd, width, height, true);

	}

	static LRESULT CALLBACK LimeResizeWndProc (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {

		if (message == WM_ENTERSIZEMOVE) {

			SDLApplication::EnterNativeModalLoop ();

		} else if (message == WM_EXITSIZEMOVE) {

			SDLApplication::ExitNativeModalLoop ();

		} else if (message == WM_SIZING) {

			PushLiveResizeEventFromRect (hwnd, (const RECT*)lParam);

		} else if (message == WM_SIZE) {

			if (wParam != SIZE_MINIMIZED) {

				// Always send WM_SIZE updates (especially final size) without throttling.
				PushLiveResizeEvent (hwnd, LOWORD (lParam), HIWORD (lParam), false);

			}

		}

		WNDPROC oldWndProc = (WNDPROC)GetPropW (hwnd, LIME_SDL_OLD_RESIZE_WNDPROC_PROP);
		if (oldWndProc) {

			return CallWindowProc (oldWndProc, hwnd, message, wParam, lParam);

		}

		return DefWindowProc (hwnd, message, wParam, lParam);

	}

	static void InstallResizeEventHook (SDL_Window* sdlWindow) {

		if (!sdlWindow) return;

		HWND hwnd = GetWin32Window (sdlWindow);
		if (!hwnd) return;
		if (GetPropW (hwnd, LIME_SDL_OLD_RESIZE_WNDPROC_PROP)) return;

		SetLastError (0);
		LONG_PTR previous = SetWindowLongPtr (hwnd, GWLP_WNDPROC, (LONG_PTR)LimeResizeWndProc);
		if (previous == 0 && GetLastError () != 0) return;

		SetPropW (hwnd, LIME_SDL_OLD_RESIZE_WNDPROC_PROP, (HANDLE)previous);
		SetPropW (hwnd, LIME_SDL_WINDOW_ID_PROP, (HANDLE)(UINT_PTR)SDL_GetWindowID (sdlWindow));

	}

	static void RestoreResizeEventHook (SDL_Window* sdlWindow) {

		if (!sdlWindow) return;

		HWND hwnd = GetWin32Window (sdlWindow);
		if (!hwnd) return;

		WNDPROC oldWndProc = (WNDPROC)GetPropW (hwnd, LIME_SDL_OLD_RESIZE_WNDPROC_PROP);
		if (oldWndProc) {

			SetWindowLongPtr (hwnd, GWLP_WNDPROC, (LONG_PTR)oldWndProc);

		}

		RemovePropW (hwnd, LIME_SDL_WINDOW_ID_PROP);
		RemovePropW (hwnd, LIME_SDL_OLD_RESIZE_WNDPROC_PROP);
		RemovePropW (hwnd, LIME_SDL_LAST_RESIZE_WIDTH_PROP);
		RemovePropW (hwnd, LIME_SDL_LAST_RESIZE_HEIGHT_PROP);
		RemovePropW (hwnd, LIME_SDL_LAST_RESIZE_TICK_PROP);

	}

	static bool EnableTransparentWindow (SDL_Window* sdlWindow) {

		if (!sdlWindow) return false;

		HWND hwnd = GetWin32Window (sdlWindow);
		if (!hwnd) return false;

		typedef struct {
			int leftWidth;
			int rightWidth;
			int topHeight;
			int bottomHeight;
		} DwmMargins;
		typedef HRESULT (WINAPI *DwmExtendFrameIntoClientAreaFunc) (HWND hwnd, const DwmMargins* margins);

		HMODULE dwmapi = LoadLibraryW (L"dwmapi.dll");
		if (!dwmapi) return false;

		DwmExtendFrameIntoClientAreaFunc extendFrame = (DwmExtendFrameIntoClientAreaFunc)GetProcAddress (dwmapi, "DwmExtendFrameIntoClientArea");
		bool enabled = false;

		if (extendFrame) {

			DwmMargins margins = { -1, -1, -1, -1 };
			enabled = SUCCEEDED (extendFrame (hwnd, &margins));

		}

		FreeLibrary (dwmapi);
		return enabled;

	}
#endif


	SDLWindow::SDLWindow (Application* application, int width, int height, int flags, const char* title) {

		activeSwapInterval = 0;
		requestedVSyncMode = (flags & WINDOW_FLAG_VSYNC) ? 1 : 0;
		sdlTexture = 0;
		sdlRenderer = 0;
		context = 0;
		useVulkan = (flags & WINDOW_FLAG_VULKAN) != 0;

		contextWidth = 0;
		contextHeight = 0;

		currentApplication = application;
		this->flags = flags;

		int sdlWindowFlags = 0;

		if (flags & WINDOW_FLAG_FULLSCREEN) sdlWindowFlags |= SDL_WINDOW_FULLSCREEN;
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

		if (flags & WINDOW_FLAG_TRANSPARENT) {

			#ifdef SDL_HINT_VIDEO_EGL_ALLOW_TRANSPARENCY
			SDL_SetHint (SDL_HINT_VIDEO_EGL_ALLOW_TRANSPARENCY, "1");
			#endif

		}

		if (flags & WINDOW_FLAG_HARDWARE) {

			if (useVulkan) {

				sdlWindowFlags |= SDL_WINDOW_VULKAN;

			} else {

				sdlWindowFlags |= SDL_WINDOW_OPENGL;

			}

			if (flags & WINDOW_FLAG_ALLOW_HIGHDPI) {

				sdlWindowFlags |= SDL_WINDOW_HIGH_PIXEL_DENSITY;

			}

			if (!useVulkan) {

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

					SDL_GL_SetAttribute (SDL_GL_DEPTH_SIZE, 32 - ((flags & WINDOW_FLAG_STENCIL_BUFFER) ? 8 : 0));

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

				if (flags & (WINDOW_FLAG_COLOR_DEPTH_32_BIT | WINDOW_FLAG_TRANSPARENT)) {

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

		}

		sdlWindow = SDL_CreateWindow (title, width, height, sdlWindowFlags);

		#if defined (IPHONE) || defined (APPLETV)
		if (!useVulkan && sdlWindow && !SDL_GL_CreateContext (sdlWindow)) {

			SDL_DestroyWindow (sdlWindow);
			SDL_GL_SetAttribute (SDL_GL_CONTEXT_MAJOR_VERSION, 2);

			sdlWindow = SDL_CreateWindow (title, width, height, sdlWindowFlags);

		}
		#endif

		if (!sdlWindow) {

			printf ("Could not create SDL window: %s.\n", SDL_GetError ());
			return;

		}

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)
		InstallResizeEventHook (sdlWindow);

		if ((flags & WINDOW_FLAG_TRANSPARENT) && !useVulkan) {

			EnableTransparentWindow (sdlWindow);

		}
		#endif

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)

		HINSTANCE handle = ::GetModuleHandle (nullptr);
		HICON icon = ::LoadIcon (handle, MAKEINTRESOURCE (1));

		if (icon != nullptr) {

			HWND hwnd = GetWin32Window (sdlWindow);
			if (hwnd) {

				#ifdef _WIN64
				::SetClassLongPtr (hwnd, GCLP_HICON, reinterpret_cast<LONG_PTR>(icon));
				#else
				::SetClassLong (hwnd, GCL_HICON, reinterpret_cast<LONG>(icon));
				#endif

			}

		}

		#endif

		if ((flags & WINDOW_FLAG_HARDWARE) && !useVulkan) {

			context = SDL_GL_CreateContext (sdlWindow);

			if (context && SDL_GL_MakeCurrent (sdlWindow, context)) {

				SetVSyncMode (requestedVSyncMode);

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

					SDL_GL_DestroyContext (context);
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

				SDL_GL_DestroyContext (context);
				context = NULL;

			}

		}

		if (!context && !useVulkan) {

			sdlRenderer = SDL_CreateRenderer (sdlWindow, "software");

			if (!sdlRenderer) {

				sdlRenderer = SDL_CreateRenderer (sdlWindow, NULL);

			}

		}

		if (context || sdlRenderer || useVulkan) {

			((SDLApplication*)currentApplication)->RegisterWindow (this);

		} else {

			printf ("Could not create SDL renderer: %s.\n", SDL_GetError ());

		}

	}


	SDLWindow::~SDLWindow () {

		if (currentApplication) {

			((SDLApplication*)currentApplication)->UnregisterWindow (this);

		}

		if (sdlRenderer) {

			SDL_DestroyRenderer (sdlRenderer);
			sdlRenderer = 0;

		} else if (context) {

			if (SDL_GL_GetCurrentContext () == context) {

				SDL_GL_MakeCurrent (sdlWindow, NULL);

			}

			SDL_GL_DestroyContext (context);
			context = 0;

		}

		if (sdlWindow) {

			#if defined (HX_WINDOWS) && !defined (HX_WINRT)
			RestoreResizeEventHook (sdlWindow);
			#endif

			SDL_DestroyWindow (sdlWindow);
			sdlWindow = 0;

		}

	}


	void SDLWindow::Alert (const char* message, const char* title) {

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)

		int count = 0;
		int speed = 0;
		bool stopOnForeground = true;

		FLASHWINFO fi;
		fi.cbSize = sizeof (FLASHWINFO);
		fi.hwnd = GetWin32Window (sdlWindow);
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

			if (currentApplication) {

				((SDLApplication*)currentApplication)->UnregisterWindow (this);

			}

			#if defined (HX_WINDOWS) && !defined (HX_WINRT)
			RestoreResizeEventHook (sdlWindow);
			#endif

			if (sdlRenderer) {

				SDL_DestroyRenderer (sdlRenderer);
				sdlRenderer = 0;

			} else if (context) {

				if (SDL_GL_GetCurrentContext () == context) {

					SDL_GL_MakeCurrent (sdlWindow, NULL);

				}

				SDL_GL_DestroyContext (context);
				context = 0;

			}

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

		return !(SDL_GetWindowFlags (sdlWindow) & SDL_WINDOW_HIDDEN);

	}


	void SDLWindow::ContextFlip () {

		if (useVulkan) {

			return;

		}

		if (context && !sdlRenderer) {

			SDL_GL_SwapWindow (sdlWindow);

		} else if (sdlRenderer) {

			SDL_RenderPresent (sdlRenderer);

		}

	}


	int SDLWindow::GetVSyncInterval () const {

		return activeSwapInterval;

	}


	int SDLWindow::GetRequestedVSyncMode () const {

		return requestedVSyncMode;

	}


	double SDLWindow::GetRefreshRate () const {

		if (!sdlWindow) {

			return 60.0;

		}

		const SDL_DisplayMode* displayMode = SDL_GetWindowFullscreenMode (sdlWindow);
		if (displayMode && displayMode->refresh_rate > 0) {

			return displayMode->refresh_rate;

		}

		SDL_DisplayID displayID = SDL_GetDisplayForWindow (sdlWindow);
		displayMode = SDL_GetCurrentDisplayMode (displayID);
		if (displayMode && displayMode->refresh_rate > 0) {

			return displayMode->refresh_rate;

		}

		return 60.0;

	}


	uint64_t SDLWindow::CreateVulkanSurface (uintptr_t instance) {

		if (!useVulkan || !instance) {

			return 0;

		}

		VkSurfaceKHR surface = 0;
		if (!SDL_Vulkan_CreateSurface (sdlWindow, (VkInstance)instance, NULL, &surface)) {

			return 0;

		}

		#if defined(__LP64__) || defined(_WIN64) || defined(__x86_64__) || defined(_M_X64) || defined(__ia64) || defined (_M_IA64) || defined(__aarch64__) || defined(__powerpc64__)
		return (uint64_t)(uintptr_t)surface;
		#else
		return (uint64_t)surface;
		#endif

	}


	void SDLWindow::GetVulkanDrawableSize (int* width, int* height) {

		if (!useVulkan) {

			if (width) *width = 0;
			if (height) *height = 0;
			return;

		}

		SDL_GetWindowSizeInPixels (sdlWindow, width, height);

	}


	bool SDLWindow::GetVulkanInstanceExtensions (unsigned int* count, const char** names) {

		if (!useVulkan) {

			if (count) *count = 0;
			return false;

		}

		Uint32 extensionCount = 0;
		char const * const *extensions = SDL_Vulkan_GetInstanceExtensions (&extensionCount);

		if (count) *count = extensionCount;

		if (!extensions) {

			return false;

		}

		if (names) {

			for (Uint32 i = 0; i < extensionCount; i++) {

				names[i] = extensions[i];

			}

		}

		return true;

	}


	void* SDLWindow::GetVulkanInstanceProcAddr () {

		if (!useVulkan) {

			return 0;

		}

		return reinterpret_cast<void*> (SDL_Vulkan_GetVkGetInstanceProcAddr ());

	}


	void* SDLWindow::ContextLock (bool useCFFIValue) {

		if (sdlRenderer) {

			int width;
			int height;

			SDL_GetCurrentRenderOutputSize (sdlRenderer, &width, &height);

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

				if (SDL_LockTexture (sdlTexture, NULL, &pixels, &pitch)) {

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

				if (SDL_LockTexture (sdlTexture, NULL, &pixels, &pitch)) {

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

		if (useVulkan) {

			return;

		}

		if (sdlWindow && context) {

			SDL_GL_MakeCurrent (sdlWindow, context);

		}

	}


	void SDLWindow::ContextUnlock () {

		if (sdlTexture) {

			SDL_UnlockTexture (sdlTexture);
			SDL_RenderClear (sdlRenderer);
			SDL_RenderTexture (sdlRenderer, sdlTexture, NULL, NULL);

		}

	}


	void SDLWindow::Focus () {

		SDL_RaiseWindow (sdlWindow);

	}


	void* SDLWindow::GetContext () {

		if (useVulkan) {

			return sdlWindow;

		}

		return context;

	}


	const char* SDLWindow::GetContextType () {

		if (useVulkan) {

			return "vulkan";

		}

		if (context) {

			return "opengl";

		} else if (sdlRenderer) {

			return "software";

		}

		return "none";

	}


	int SDLWindow::GetDisplay () {

		SDL_DisplayID* displays = NULL;
		int displayCount = 0;
		int displayIndex = 0;
		SDL_DisplayID displayID = SDL_GetDisplayForWindow (sdlWindow);

		displays = SDL_GetDisplays (&displayCount);

		if (displays) {

			for (int i = 0; i < displayCount; i++) {

				if (displays[i] == displayID) {

					displayIndex = i;
					break;

				}

			}

			SDL_free (displays);

		}

		return displayIndex;

	}


	void SDLWindow::GetDisplayMode (DisplayMode* displayMode) {

		const SDL_DisplayMode* fullscreenMode = SDL_GetWindowFullscreenMode (sdlWindow);
		const SDL_DisplayMode* currentMode = SDL_GetCurrentDisplayMode (SDL_GetDisplayForWindow (sdlWindow));
		const SDL_DisplayMode* mode = fullscreenMode ? fullscreenMode : currentMode;

		if (!mode) {

			displayMode->width = GetWidth ();
			displayMode->height = GetHeight ();
			displayMode->pixelFormat = RGBA32;
			displayMode->refreshRate = 60;
			return;

		}

		displayMode->width = mode->w;
		displayMode->height = mode->h;

		switch (mode->format) {

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

		displayMode->refreshRate = mode->refresh_rate;

	}


	int SDLWindow::GetHeight () {

		int width = 0;
		int height = 0;

		SDL_GetWindowSize (sdlWindow, &width, &height);

		return height;

	}


	uint32_t SDLWindow::GetID () {

		return SDL_GetWindowID (sdlWindow);

	}


	bool SDLWindow::GetMouseLock () {

		return SDL_GetWindowRelativeMouseMode (sdlWindow);

	}


	float SDLWindow::GetOpacity () {

		return SDL_GetWindowOpacity (sdlWindow);

	}


	double SDLWindow::GetScale () {

		if (sdlRenderer) {

			int outputWidth;
			int outputHeight;

			SDL_GetCurrentRenderOutputSize (sdlRenderer, &outputWidth, &outputHeight);

			int width;
			int height;

			SDL_GetWindowSize (sdlWindow, &width, &height);

			if (width <= 0) return 1;

			double scale = double (outputWidth) / width;
			return scale;

		} else if (context) {

			int outputWidth;
			int outputHeight;

			SDL_GetWindowSizeInPixels (sdlWindow, &outputWidth, &outputHeight);

			int width;
			int height;

			SDL_GetWindowSize (sdlWindow, &width, &height);

			if (width <= 0) return 1;

			double scale = double (outputWidth) / width;
			return scale;

		}

		return 1;

	}


	bool SDLWindow::GetTextInputEnabled () {

		return SDL_TextInputActive (sdlWindow);

	}


	int SDLWindow::GetWidth () {

		int width = 0;
		int height = 0;

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

				SDL_GetCurrentRenderOutputSize (sdlRenderer, &bounds.w, &bounds.h);

			}

			buffer->Resize (bounds.w, bounds.h, 32);

			SDL_Surface* surface = SDL_RenderReadPixels (sdlRenderer, &bounds);

			if (surface) {

				SDL_Surface* converted = SDL_ConvertSurface (surface, SDL_PIXELFORMAT_ABGR8888);
				SDL_Surface* source = converted ? converted : surface;
				Uint8* input = (Uint8*)source->pixels;
				Uint8* output = (Uint8*)buffer->data->buffer->b;
				int copyPitch = source->pitch < buffer->Stride () ? source->pitch : buffer->Stride ();

				for (int y = 0; y < bounds.h; y++) {

					memcpy (output + y * buffer->Stride (), input + y * source->pitch, copyPitch);

				}

				if (converted) {

					SDL_DestroySurface (converted);

				}

				SDL_DestroySurface (surface);

			}

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

			SDL_SetWindowBordered (sdlWindow, false);

		} else {

			SDL_SetWindowBordered (sdlWindow, true);

		}

		return borderless;

	}


	void SDLWindow::SetCursor (Cursor cursor) {

		if (cursor != currentCursor) {

			if (currentCursor == HIDDEN) {

				SDL_ShowCursor ();

			}

			switch (cursor) {

				case HIDDEN:

					SDL_HideCursor ();

				case CROSSHAIR:

					if (!SDLCursor::crosshairCursor) {

						SDLCursor::crosshairCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_CROSSHAIR);

					}

					SDL_SetCursor (SDLCursor::crosshairCursor);
					break;

				case MOVE:

					if (!SDLCursor::moveCursor) {

						SDLCursor::moveCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_MOVE);

					}

					SDL_SetCursor (SDLCursor::moveCursor);
					break;

				case POINTER:

					if (!SDLCursor::pointerCursor) {

						SDLCursor::pointerCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_POINTER);

					}

					SDL_SetCursor (SDLCursor::pointerCursor);
					break;

				case RESIZE_NESW:

					if (!SDLCursor::resizeNESWCursor) {

						SDLCursor::resizeNESWCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_NESW_RESIZE);

					}

					SDL_SetCursor (SDLCursor::resizeNESWCursor);
					break;

				case RESIZE_NS:

					if (!SDLCursor::resizeNSCursor) {

						SDLCursor::resizeNSCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_NS_RESIZE);

					}

					SDL_SetCursor (SDLCursor::resizeNSCursor);
					break;

				case RESIZE_NWSE:

					if (!SDLCursor::resizeNWSECursor) {

						SDLCursor::resizeNWSECursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_NWSE_RESIZE);

					}

					SDL_SetCursor (SDLCursor::resizeNWSECursor);
					break;

				case RESIZE_WE:

					if (!SDLCursor::resizeWECursor) {

						SDLCursor::resizeWECursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_EW_RESIZE);

					}

					SDL_SetCursor (SDLCursor::resizeWECursor);
					break;

				case TEXT:

					if (!SDLCursor::textCursor) {

						SDLCursor::textCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_TEXT);

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

						SDLCursor::waitArrowCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_PROGRESS);

					}

					SDL_SetCursor (SDLCursor::waitArrowCursor);
					break;

				default:

					if (!SDLCursor::arrowCursor) {

						SDLCursor::arrowCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_DEFAULT);

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

		SDL_DisplayMode mode = {
			SDL_GetDisplayForWindow (sdlWindow),
			(SDL_PixelFormat)pixelFormat,
			displayMode->width,
			displayMode->height,
			SDL_GetWindowPixelDensity (sdlWindow),
			(float)displayMode->refreshRate,
			0,
			0,
			NULL
		};

		if (SDL_SetWindowFullscreenMode (sdlWindow, &mode)) {

			displayModeSet = true;

			if (SDL_GetWindowFlags (sdlWindow) & SDL_WINDOW_FULLSCREEN) {

				SDL_SetWindowFullscreen (sdlWindow, true);

			}

		}

	}


	bool SDLWindow::SetFullscreen (bool fullscreen) {

		if (fullscreen) {

			if (displayModeSet) {

				SDL_SetWindowFullscreen (sdlWindow, true);

			} else {

				SDL_SetWindowFullscreen (sdlWindow, true);

			}

		} else {

			SDL_SetWindowFullscreen (sdlWindow, false);

		}

		return fullscreen;

	}


	void SDLWindow::SetIcon (ImageBuffer *imageBuffer) {

		SDL_Surface *surface = SDL_CreateSurfaceFrom (imageBuffer->width, imageBuffer->height, SDL_GetPixelFormatForMasks (imageBuffer->bitsPerPixel, 0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000), imageBuffer->data->buffer->b, imageBuffer->Stride ());

		if (surface) {

			SDL_SetWindowIcon (sdlWindow, surface);
			SDL_DestroySurface (surface);

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

			SDL_SetWindowRelativeMouseMode (sdlWindow, true);

		} else {

			SDL_SetWindowRelativeMouseMode (sdlWindow, false);

		}

	}


	void SDLWindow::SetOpacity (float opacity) {

		SDL_SetWindowOpacity (sdlWindow, opacity);

	}


	bool SDLWindow::SetResizable (bool resizable) {

		#ifndef EMSCRIPTEN

		if (resizable) {

			SDL_SetWindowResizable (sdlWindow, true);

		} else {

			SDL_SetWindowResizable (sdlWindow, false);

		}

		return (SDL_GetWindowFlags (sdlWindow) & SDL_WINDOW_RESIZABLE);

		#else

		return resizable;

		#endif

	}


	void SDLWindow::SetTextInputEnabled (bool enabled) {

		if (enabled) {

			SDL_StartTextInput (sdlWindow);

		} else {

			SDL_StopTextInput (sdlWindow);

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

		SDL_SetTextInputArea (sdlWindow, &bounds, 0);
	}


	void SDLWindow::SetVSyncMode (int vsyncMode) {

		requestedVSyncMode = vsyncMode;
		activeSwapInterval = 0;

		if (useVulkan) {

			switch (vsyncMode) {

				case 1:
					activeSwapInterval = 1;
					flags |= WINDOW_FLAG_VSYNC;
					break;

				case 2:
					activeSwapInterval = -1;
					flags |= WINDOW_FLAG_VSYNC;
					break;

				case 3:
					activeSwapInterval = 1;
					flags |= WINDOW_FLAG_VSYNC;
					break;

				default:
					flags &= ~WINDOW_FLAG_VSYNC;
					break;

			}

			return;

		}

		if (!sdlWindow || !context || sdlRenderer) {

			flags &= ~WINDOW_FLAG_VSYNC;
			return;

		}

		SDL_Window* oldWindow = SDL_GL_GetCurrentWindow ();
		SDL_GLContext oldContext = SDL_GL_GetCurrentContext ();
		bool restoreContext = (oldWindow != sdlWindow || oldContext != context);

		if (restoreContext) {

			SDL_GL_MakeCurrent (sdlWindow, context);

		}

		switch (vsyncMode) {

			case 1:

				if (SDL_GL_SetSwapInterval (1)) {

					activeSwapInterval = 1;

				}

				break;

			case 2:
			case 3:

				if (SDL_GL_SetSwapInterval (-1)) {

					activeSwapInterval = -1;

				} else if (SDL_GL_SetSwapInterval (1)) {

					activeSwapInterval = 1;

				}

				break;

			default:

				SDL_GL_SetSwapInterval (0);
				activeSwapInterval = 0;
				break;

		}

		if (activeSwapInterval == 0) {

			SDL_GL_SetSwapInterval (0);
			flags &= ~WINDOW_FLAG_VSYNC;

		} else {

			flags |= WINDOW_FLAG_VSYNC;

		}

		if (restoreContext && oldWindow && oldContext) {

			SDL_GL_MakeCurrent (oldWindow, oldContext);

		}
	}


	const char* SDLWindow::SetTitle (const char* title) {

		SDL_SetWindowTitle (sdlWindow, title);

		return title;

	}


	bool SDLWindow::SetAlwaysOnTop (bool alwaysOnTop) {

		if (alwaysOnTop) {

			SDL_SetWindowAlwaysOnTop (sdlWindow, true);

		} else {

			SDL_SetWindowAlwaysOnTop (sdlWindow, false);

		}

		return alwaysOnTop;

	}


	void SDLWindow::WarpMouse (int x, int y) {

		SDL_WarpMouseInWindow (sdlWindow, x, y);

	}


	Window* CreateWindow (Application* application, int width, int height, int flags, const char* title) {

		SDLWindow* window = new SDLWindow (application, width, height, flags, title);

		if (!window->sdlWindow) {

			delete window;
			return 0;

		}

		return window;

	}


}
