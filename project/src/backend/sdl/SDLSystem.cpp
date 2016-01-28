#include <graphics/PixelFormat.h>
#include <math/Rectangle.h>
#include <system/Clipboard.h>
#include <system/JNI.h>
#include <system/System.h>

#ifdef HX_MACOS
#include <CoreFoundation/CoreFoundation.h>
#endif

#ifdef HX_WINDOWS
#include <shlobj.h>
#include <stdio.h>
//#include <io.h>
//#include <fcntl.h>
#ifdef __MINGW32__
#ifndef CSIDL_MYDOCUMENTS
#define CSIDL_MYDOCUMENTS CSIDL_PERSONAL
#endif
#ifndef SHGFP_TYPE_CURRENT
#define SHGFP_TYPE_CURRENT 0
#endif
#endif
#if UNICODE
#define WIN_StringToUTF8(S) SDL_iconv_string("UTF-8", "UTF-16LE", (char *)(S), (SDL_wcslen(S)+1)*sizeof(WCHAR))
#define WIN_UTF8ToString(S) (WCHAR *)SDL_iconv_string("UTF-16LE", "UTF-8", (char *)(S), SDL_strlen(S)+1)
#else
#define WIN_StringToUTF8(S) SDL_iconv_string("UTF-8", "ASCII", (char *)(S), (SDL_strlen(S)+1))
#define WIN_UTF8ToString(S) SDL_iconv_string("ASCII", "UTF-8", (char *)(S), SDL_strlen(S)+1)
#endif
#endif

#include <SDL.h>
#include <string>


namespace lime {
	
	
	static int id_bounds;
	static int id_currentMode;
	static int id_dpi;
	static int id_height;
	static int id_name;
	static int id_pixelFormat;
	static int id_refreshRate;
	static int id_supportedModes;
	static int id_width;
	static bool init = false;
	
	
	const char* Clipboard::GetText () {
		
		return SDL_GetClipboardText ();
		
	}
	
	
	bool Clipboard::HasText () {
		
		return SDL_HasClipboardText ();
		
	}
	
	
	void Clipboard::SetText (const char* text) {
		
		SDL_SetClipboardText (text);
		
	}
	
	
	void *JNI::GetEnv () {
		
		#ifdef ANDROID
		return SDL_AndroidGetJNIEnv ();
		#else
		return 0;
		#endif
		
	}
	
	
	bool System::GetAllowScreenTimeout () {
		
		return SDL_IsScreenSaverEnabled ();
		
	}
	
	
	const char* System::GetDirectory (SystemDirectory type, const char* company, const char* title) {
		
		switch (type) {
			
			case APPLICATION:
				
				return SDL_GetBasePath ();
				break;
			
			case APPLICATION_STORAGE:
				
				return SDL_GetPrefPath (company, title);
				break;
			
			case DESKTOP: {
				
				#if defined (HX_WINRT)
				
				Windows::Storage::StorageFolder folder = Windows::Storage::KnownFolders::HomeGroup;
				std::wstring resultW (folder->Begin ());
				std::string result (resultW.begin (), resultW.end ());
				return result.c_str ();
				
				#elif defined (HX_WINDOWS)
				
				char result[MAX_PATH] = "";
				SHGetFolderPath (NULL, CSIDL_DESKTOPDIRECTORY, NULL, SHGFP_TYPE_CURRENT, result);
				return WIN_StringToUTF8 (result);
				
				#else
				
				std::string result = std::string (getenv ("HOME")) + std::string ("/Desktop");
				return result.c_str ();
				
				#endif
				break;
				
			}
			
			case DOCUMENTS: {
				
				#if defined (HX_WINRT)
				
				Windows::Storage::StorageFolder folder = Windows::Storage::KnownFolders::DocumentsLibrary;
				std::wstring resultW (folder->Begin ());
				std::string result (resultW.begin (), resultW.end ());
				return result.c_str ();
				
				#elif defined (HX_WINDOWS)
				
				char result[MAX_PATH] = "";
				SHGetFolderPath (NULL, CSIDL_MYDOCUMENTS, NULL, SHGFP_TYPE_CURRENT, result);
				return WIN_StringToUTF8 (result);
				
				#else
				
				std::string result = std::string (getenv ("HOME")) + std::string ("/Documents");
				return result.c_str ();
				
				#endif
				break;
				
			}
			
			case FONTS: {
				
				#if defined (HX_WINRT)
				
				return 0;
				
				#elif defined (HX_WINDOWS)
				
				char result[MAX_PATH] = "";
				SHGetFolderPath (NULL, CSIDL_FONTS, NULL, SHGFP_TYPE_CURRENT, result);
				return WIN_StringToUTF8 (result);
				
				#elif defined (HX_MACOS)
				
				return "/Library/Fonts";
				
				#elif defined (IPHONEOS)
				
				return "/System/Library/Fonts";
				
				#elif defined (ANDROID)
				
				return "/system/fonts";
				
				#elif defined (BLACKBERRY)
				
				return "/usr/fonts/font_repository/monotype";
				
				#else
				
				return "/usr/share/fonts/truetype";
				
				#endif
				break;
				
			}
			
			case USER: {
				
				#if defined (HX_WINRT)
				
				Windows::Storage::StorageFolder folder = Windows::Storage::ApplicationData::Current->RoamingFolder;
				std::wstring resultW (folder->Begin ());
				std::string result (resultW.begin (), resultW.end ());
				return result.c_str ();
				
				#elif defined (HX_WINDOWS)
				
				char result[MAX_PATH] = "";
				SHGetFolderPath (NULL, CSIDL_PROFILE, NULL, SHGFP_TYPE_CURRENT, result);
				return WIN_StringToUTF8 (result);
				
				#else
				
				std::string result = getenv ("HOME");
				return result.c_str ();
				
				#endif
				break;
				
			}
			
		}
		
		return 0;
		
	}
	
	
	value System::GetDisplay (int id) {
		
		if (!init) {
			
			id_bounds = val_id ("bounds");
			id_currentMode = val_id ("currentMode");
			id_dpi = val_id ("dpi");
			id_height = val_id ("height");
			id_name = val_id ("name");
			id_pixelFormat = val_id ("pixelFormat");
			id_refreshRate = val_id ("refreshRate");
			id_supportedModes = val_id ("supportedModes");
			id_width = val_id ("width");
			init = true;
			
		}
		
		int numDisplays = GetNumDisplays ();
		
		if (id < 0 || id >= numDisplays) {
			
			return alloc_null ();
			
		}
		
		value display = alloc_empty_object ();
		alloc_field (display, id_name, alloc_string (SDL_GetDisplayName (id)));
		
		SDL_Rect bounds = { 0, 0, 0, 0 };
		SDL_GetDisplayBounds (id, &bounds);
		alloc_field (display, id_bounds, Rectangle (bounds.x, bounds.y, bounds.w, bounds.h).Value ());
		
		float dpi = 72.0;
		#ifndef EMSCRIPTEN
		SDL_GetDisplayDPI (id, &dpi, NULL, NULL);
		#endif
		alloc_field (display, id_dpi, alloc_float (dpi));
		
		SDL_DisplayMode currentDisplayMode = { SDL_PIXELFORMAT_UNKNOWN, 0, 0, 0, 0 };
		SDL_DisplayMode displayMode = { SDL_PIXELFORMAT_UNKNOWN, 0, 0, 0, 0 };
		
		SDL_GetCurrentDisplayMode (id, &currentDisplayMode);
		
		int numDisplayModes = SDL_GetNumDisplayModes (id);
		value supportedModes = alloc_array (numDisplayModes);
		value mode;
		
		for (int i = 0; i < numDisplayModes; i++) {
			
			SDL_GetDisplayMode (id, i, &displayMode);
			
			if (displayMode.format == currentDisplayMode.format && displayMode.w == currentDisplayMode.w && displayMode.h == currentDisplayMode.h && displayMode.refresh_rate == currentDisplayMode.refresh_rate) {
				
				alloc_field (display, id_currentMode, alloc_int (i));
				
			}
			
			mode = alloc_empty_object ();
			alloc_field (mode, id_height, alloc_int (displayMode.h));
			
			switch (displayMode.format) {
				
				case SDL_PIXELFORMAT_ARGB8888:
					
					alloc_field (mode, id_pixelFormat, alloc_int (ARGB32));
					break;
				
				case SDL_PIXELFORMAT_BGRA8888:
				case SDL_PIXELFORMAT_BGRX8888:
					
					alloc_field (mode, id_pixelFormat, alloc_int (BGRA32));
					break;
				
				default:
					
					alloc_field (mode, id_pixelFormat, alloc_int (RGBA32));
				
			}
			
			alloc_field (mode, id_refreshRate, alloc_int (displayMode.refresh_rate));
			alloc_field (mode, id_width, alloc_int (displayMode.w));
			
			val_array_set_i (supportedModes, i, mode);
			
		}
		
		alloc_field (display, id_supportedModes, supportedModes);
		return display;
		
	}
	
	
	int System::GetNumDisplays () {
		
		return SDL_GetNumVideoDisplays ();
		
	}
	
	
	double System::GetTimer () {
		
		return SDL_GetTicks ();
		
	}
	
	
	bool System::SetAllowScreenTimeout (bool allow) {
		
		if (allow) {
			
			SDL_EnableScreenSaver ();
			
		} else {
			
			SDL_DisableScreenSaver ();
			
		}
		
		return allow;
		
	}
	
	
	FILE* FILE_HANDLE::getFile () {
		
		#ifndef HX_WINDOWS
		
		switch (((SDL_RWops*)handle)->type) {
			
			case SDL_RWOPS_STDFILE:
				
				return ((SDL_RWops*)handle)->hidden.stdio.fp;
			
			case SDL_RWOPS_JNIFILE:
			{
				#ifdef ANDROID
				FILE* file = ::fdopen (((SDL_RWops*)handle)->hidden.androidio.fd, "rb");
				::fseek (file, ((SDL_RWops*)handle)->hidden.androidio.offset, 0);
				return file;
				#endif
			}
				
			case SDL_RWOPS_WINFILE:
			{
				/*#ifdef HX_WINDOWS
				printf("SDKFLJDSLFKJ\n");
				int fd = _open_osfhandle ((intptr_t)((SDL_RWops*)handle)->hidden.windowsio.h, _O_RDONLY);
				
				if (fd != -1) {
					printf("SDKFLJDSLFKJ\n");
					return ::fdopen (fd, "rb");
					
				}
				#endif*/
			}
			
		}
		
		return NULL;
		
		#else
		
		return (FILE*)handle;
		
		#endif
		
	}
	
	
	int FILE_HANDLE::getLength () {
		
		#ifndef HX_WINDOWS
		
		return SDL_RWsize (((SDL_RWops*)handle));
		
		#else
		
		return 0;
		
		#endif
		
	}
	
	
	bool FILE_HANDLE::isFile () {
		
		#ifndef HX_WINDOWS
		
		return ((SDL_RWops*)handle)->type == SDL_RWOPS_STDFILE;
		
		#else
		
		return true;
		
		#endif
		
	}
	
	
	int fclose (FILE_HANDLE *stream) {
		
		#ifndef HX_WINDOWS
		
		if (stream) {
			
			int code = SDL_RWclose ((SDL_RWops*)stream->handle);
			delete stream;
			return code;
			
		}
		
		return 0;
		
		#else
		
		if (stream) {
			
			int code = ::fclose ((FILE*)stream->handle);
			delete stream;
			return code;
			
		}
		
		return 0;
		
		#endif
		
	}
	
	
	FILE_HANDLE *fdopen (int fd, const char *mode) {
		
		#ifndef HX_WINDOWS
		
		FILE* fp = ::fdopen (fd, mode);
		SDL_RWops *result = SDL_RWFromFP (fp, SDL_TRUE);
		
		if (result) {
			
			return new FILE_HANDLE (result);
			
		}
		
		return NULL;
		
		#else
		
		FILE* result = ::fdopen (fd, mode);
		
		if (result) {
			
			return new FILE_HANDLE (result);
			
		}
		
		return NULL;
		
		#endif
		
	}
	
	
	FILE_HANDLE *fopen (const char *filename, const char *mode) {
		
		#ifndef HX_WINDOWS
		
		SDL_RWops *result;
		
		#ifdef HX_MACOS
		
		result = SDL_RWFromFile (filename, "rb");
		
		if (!result) {
			
			CFStringRef str = CFStringCreateWithCString (NULL, filename, kCFStringEncodingUTF8);
			CFURLRef path = CFBundleCopyResourceURL (CFBundleGetMainBundle (), str, NULL, NULL);
			CFRelease (str);
			
			if (path) {
				
				str = CFURLCopyPath (path);
				CFIndex maxSize = CFStringGetMaximumSizeForEncoding (CFStringGetLength (str), kCFStringEncodingUTF8);
				char *buffer = (char *)malloc (maxSize);
				
				if (CFStringGetCString (str, buffer, maxSize, kCFStringEncodingUTF8)) {
					
					result = SDL_RWFromFP (::fopen (buffer, "rb"), SDL_TRUE);
					free (buffer);
					
				}
				
				CFRelease (str);
				CFRelease (path);
				
			}
			
		}
		#else
		result = SDL_RWFromFile (filename, mode);
		#endif
		
		if (result) {
			
			return new FILE_HANDLE (result);
			
		}
		
		return NULL;
		
		#else
		
		FILE* result = ::fopen (filename, mode);
		
		if (result) {
			
			return new FILE_HANDLE (result);
			
		}
		
		return NULL;
		
		#endif
		
	}
	
	
	size_t fread (void *ptr, size_t size, size_t count, FILE_HANDLE *stream) {
		
		#ifndef HX_WINDOWS
		
		return SDL_RWread (stream ? (SDL_RWops*)stream->handle : NULL, ptr, size, count);
		
		#else
		
		return ::fread (ptr, size, count, (FILE*)stream->handle);
		
		#endif
		
	}
	
	
	int fseek (FILE_HANDLE *stream, long int offset, int origin) {
		
		#ifndef HX_WINDOWS
		
		return SDL_RWseek (stream ? (SDL_RWops*)stream->handle : NULL, offset, origin);
		
		#else
		
		return ::fseek ((FILE*)stream->handle, offset, origin);
		
		#endif
		
	}
	
	
	long int ftell (FILE_HANDLE *stream) {
		
		#ifndef HX_WINDOWS
		
		return SDL_RWtell (stream ? (SDL_RWops*)stream->handle : NULL);
		
		#else
		
		return ::ftell ((FILE*)stream->handle);
		
		#endif
		
	}
	
	
	size_t fwrite (const void *ptr, size_t size, size_t count, FILE_HANDLE *stream) {
		
		#ifndef HX_WINDOWS
		
		return SDL_RWwrite (stream ? (SDL_RWops*)stream->handle : NULL, ptr, size, count);
		
		#else
		
		return ::fwrite (ptr, size, count, (FILE*)stream->handle);
		
		#endif
		
	}
	
	
}