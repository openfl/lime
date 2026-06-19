#include <graphics/PixelFormat.h>
#include <math/Rectangle.h>
#include <system/Clipboard.h>
#include <system/Display.h>
#include <system/DisplayMode.h>
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

#ifdef ANDROID
#include <android/asset_manager_jni.h>
#endif

#include <SDL3/SDL.h>
#include <string>

#include <locale>
#include <codecvt>

using wstring_convert = std::wstring_convert<std::codecvt_utf8<wchar_t>>;


namespace lime {


	static int id_bounds;
	static int id_currentMode;
	static int id_dpi;
	static int id_height;
	static int id_name;
	static int id_orientation;
	static int id_pixelFormat;
	static int id_refreshRate;
	static int id_supportedModes;
	static int id_width;
	static int id_safeArea;
	static bool init = false;

	static SDL_DisplayID GetSDLDisplayID (int displayIndex) {

		int count = 0;
		SDL_DisplayID* displays = SDL_GetDisplays (&count);
		SDL_DisplayID displayID = 0;

		if (displays) {

			if (displayIndex >= 0 && displayIndex < count) {

				displayID = displays[displayIndex];

			}

			SDL_free (displays);

		}

		return displayID;

	}


	static int GetSDLDisplayCount () {

		int count = 0;
		SDL_DisplayID* displays = SDL_GetDisplays (&count);

		if (displays) {

			SDL_free (displays);

		}

		return count;

	}


	static PixelFormat GetPixelFormat (SDL_PixelFormat format) {

		switch (format) {

			case SDL_PIXELFORMAT_ARGB8888:

				return ARGB32;

			case SDL_PIXELFORMAT_BGRA8888:
			case SDL_PIXELFORMAT_BGRX8888:

				return BGRA32;

			default:

				return RGBA32;

		}

	}


	static void SetDisplayMode (DisplayMode* mode, const SDL_DisplayMode* displayMode) {

		if (!mode || !displayMode) return;

		mode->height = displayMode->h;
		mode->pixelFormat = GetPixelFormat (displayMode->format);
		mode->refreshRate = (int)displayMode->refresh_rate;
		mode->width = displayMode->w;

	}


	const char* Clipboard::GetText () {

		return SDL_GetClipboardText ();

	}


	bool Clipboard::HasText () {

		return SDL_HasClipboardText ();

	}


	bool Clipboard::SetText (const char* text) {

		return SDL_SetClipboardText (text);

	}


	void *JNI::GetEnv () {

		#ifdef ANDROID
		return SDL_AndroidGetJNIEnv ();
		#else
		return 0;
		#endif

	}


	bool System::GetAllowScreenTimeout () {

		return SDL_ScreenSaverEnabled ();

	}


	std::wstring* System::GetDirectory (SystemDirectory type, const char* company, const char* title) {

		std::wstring* result = 0;
		System::GCEnterBlocking ();

		switch (type) {

			case APPLICATION: {

				const char* path = SDL_GetBasePath ();

				if (path != nullptr) {

					wstring_convert converter;
					result = new std::wstring (converter.from_bytes(path));

				}

				break;

			}

			case APPLICATION_STORAGE: {

				char* path = SDL_GetPrefPath (company, title);

				if (path != nullptr) {

					wstring_convert converter;
					result = new std::wstring (converter.from_bytes(path));
					SDL_free (path);

				}

				break;

			}

			case DESKTOP: {

				#if defined (HX_WINRT)

				Windows::Storage::StorageFolder^ folder = Windows::Storage::KnownFolders::HomeGroup;
				result = new std::wstring (folder->Path->Data ());

				#elif defined (HX_WINDOWS)

				WCHAR folderPath[MAX_PATH] = L"";
				SHGetFolderPathW (NULL, CSIDL_DESKTOPDIRECTORY, NULL, SHGFP_TYPE_CURRENT, folderPath);
				result = new std::wstring (folderPath);

				#elif defined (IPHONE)

				result = System::GetIOSDirectory (type);

				#elif !defined (ANDROID)

				char const* home = getenv ("HOME");

				if (home != NULL) {

					std::string path = std::string (home) + std::string ("/Desktop");
					wstring_convert converter;
					result = new std::wstring (converter.from_bytes(path));

				}

				#endif
				break;

			}

			case DOCUMENTS: {

				#if defined (HX_WINRT)

				Windows::Storage::StorageFolder^ folder = Windows::Storage::KnownFolders::DocumentsLibrary;
				result = new std::wstring (folder->Path->Data ());

				#elif defined (HX_WINDOWS)

				WCHAR folderPath[MAX_PATH] = L"";
				SHGetFolderPathW (NULL, CSIDL_MYDOCUMENTS, NULL, SHGFP_TYPE_CURRENT, folderPath);
				result = new std::wstring (folderPath);

				#elif defined (IPHONE)

				result = System::GetIOSDirectory (type);

				#elif defined (ANDROID)

				result = new std::wstring (L"/mnt/sdcard/Documents");

				#else

				char const* home = getenv ("HOME");

				if (home != NULL) {

					std::string path = std::string (home) + std::string ("/Documents");
					wstring_convert converter;
					result = new std::wstring (converter.from_bytes(path));

				}

				#endif
				break;

			}

			case FONTS: {

				#if defined (HX_WINRT)

				// TODO

				#elif defined (HX_WINDOWS)

				WCHAR folderPath[MAX_PATH] = L"";
				SHGetFolderPathW (NULL, CSIDL_FONTS, NULL, SHGFP_TYPE_CURRENT, folderPath);
				result = new std::wstring (folderPath);

				#elif defined (HX_MACOS)

				result = new std::wstring (L"/Library/Fonts");

				#elif defined (IPHONE)

				result = new std::wstring (L"/System/Library/Fonts");

				#elif defined (ANDROID)

				result = new std::wstring (L"/system/fonts");

				#elif defined (BLACKBERRY)

				result = new std::wstring (L"/usr/fonts/font_repository/monotype");

				#else

				result = new std::wstring (L"/usr/share/fonts/truetype");

				#endif
				break;

			}

			case USER: {

				#if defined (HX_WINRT)

				Windows::Storage::StorageFolder^ folder = Windows::Storage::ApplicationData::Current->RoamingFolder;
				result = new std::wstring (folder->Path->Data ());

				#elif defined (HX_WINDOWS)

				WCHAR folderPath[MAX_PATH] = L"";
				SHGetFolderPathW (NULL, CSIDL_PROFILE, NULL, SHGFP_TYPE_CURRENT, folderPath);
				result = new std::wstring (folderPath);

				#elif defined (IPHONE)

				result = System::GetIOSDirectory (type);

				#elif defined (ANDROID)

				result = new std::wstring (L"/mnt/sdcard");

				#else

				char const* home = getenv ("HOME");

				if (home != NULL) {

					std::string path = std::string (home);
					wstring_convert converter;
					result = new std::wstring (converter.from_bytes(path));

				}

				#endif
				break;

			}

		}

		System::GCExitBlocking ();
		return result;

	}


	void* System::GetDisplay (bool useCFFIValue, int id) {

		if (useCFFIValue) {

			if (!init) {

				id_bounds = val_id ("bounds");
				id_currentMode = val_id ("currentMode");
				id_dpi = val_id ("dpi");
				id_height = val_id ("height");
				id_name = val_id ("name");
				id_orientation = val_id ("orientation");
				id_pixelFormat = val_id ("pixelFormat");
				id_refreshRate = val_id ("refreshRate");
				id_supportedModes = val_id ("supportedModes");
				id_width = val_id ("width");
				id_safeArea = val_id ("safeArea");
				init = true;

			}

			int numDisplays = GetNumDisplays ();

			if (id < 0 || id >= numDisplays) {

				return alloc_null ();

			}

			SDL_DisplayID displayID = GetSDLDisplayID (id);

			if (!displayID) {

				return alloc_null ();

			}

			value display = alloc_empty_object ();
			const char* displayName = SDL_GetDisplayName (displayID);
			alloc_field (display, id_name, alloc_string (displayName ? displayName : ""));

			SDL_Rect bounds = { 0, 0, 0, 0 };
			SDL_GetDisplayBounds (displayID, &bounds);
			alloc_field (display, id_bounds, Rectangle (bounds.x, bounds.y, bounds.w, bounds.h).Value ());

			Rectangle safeAreaInsets;
			Display::GetSafeAreaInsets(id, &safeAreaInsets);
			alloc_field (display, id_safeArea,
				Rectangle (bounds.x + safeAreaInsets.x,
					bounds.y + safeAreaInsets.y,
					bounds.w - safeAreaInsets.x - safeAreaInsets.width,
					bounds.h - safeAreaInsets.y - safeAreaInsets.height).Value ());

			float dpi = 72.0;
			#ifndef EMSCRIPTEN
			dpi *= SDL_GetDisplayContentScale (displayID);
			#endif
			alloc_field (display, id_dpi, alloc_float (dpi));

			SDL_DisplayOrientation orientation = SDL_GetCurrentDisplayOrientation (displayID);
			alloc_field (display, id_orientation, alloc_int (orientation));

			DisplayMode mode;

			SetDisplayMode (&mode, SDL_GetDesktopDisplayMode (displayID));

			alloc_field (display, id_currentMode, (value)mode.Value ());

			int numDisplayModes = 0;
			SDL_DisplayMode** displayModes = SDL_GetFullscreenDisplayModes (displayID, &numDisplayModes);
			value supportedModes = alloc_array (numDisplayModes);

			for (int i = 0; i < numDisplayModes; i++) {

				SetDisplayMode (&mode, displayModes ? displayModes[i] : NULL);

				val_array_set_i (supportedModes, i, (value)mode.Value ());

			}

			if (displayModes) {

				SDL_free (displayModes);

			}

			alloc_field (display, id_supportedModes, supportedModes);
			return display;

		} else {

			const int id_bounds = hl_hash_utf8 ("bounds");
			const int id_currentMode = hl_hash_utf8 ("currentMode");
			const int id_dpi = hl_hash_utf8 ("dpi");
			const int id_height = hl_hash_utf8 ("height");
			const int id_name = hl_hash_utf8 ("name");
			const int id_orientation = hl_hash_utf8 ("orientation");
			const int id_pixelFormat = hl_hash_utf8 ("pixelFormat");
			const int id_refreshRate = hl_hash_utf8 ("refreshRate");
			const int id_supportedModes = hl_hash_utf8 ("supportedModes");
			const int id_width = hl_hash_utf8 ("width");
			const int id_safeArea = hl_hash_utf8 ("safeArea");
			const int id_x = hl_hash_utf8 ("x");
			const int id_y = hl_hash_utf8 ("y");

			int numDisplays = GetNumDisplays ();

			if (id < 0 || id >= numDisplays) {

				return 0;

			}

			SDL_DisplayID displayID = GetSDLDisplayID (id);

			if (!displayID) {

				return 0;

			}

			vdynamic* display = (vdynamic*)hl_alloc_dynobj ();

			const char* displayName = SDL_GetDisplayName (displayID);
			if (!displayName) displayName = "";
			char* _displayName = (char*)malloc(strlen(displayName) + 1);
			strcpy (_displayName, displayName);
			hl_dyn_setp (display, id_name, &hlt_bytes, _displayName);

			SDL_Rect bounds = { 0, 0, 0, 0 };
			SDL_GetDisplayBounds (displayID, &bounds);

			vdynamic* _bounds = (vdynamic*)hl_alloc_dynobj ();
			hl_dyn_seti (_bounds, id_x, &hlt_i32, bounds.x);
			hl_dyn_seti (_bounds, id_y, &hlt_i32, bounds.y);
			hl_dyn_seti (_bounds, id_width, &hlt_i32, bounds.w);
			hl_dyn_seti (_bounds, id_height, &hlt_i32, bounds.h);

			hl_dyn_setp (display, id_bounds, &hlt_dynobj, _bounds);

			Rectangle safeAreaInsets;
			Display::GetSafeAreaInsets(id, &safeAreaInsets);
			vdynamic* _safeArea = (vdynamic*)hl_alloc_dynobj ();
			hl_dyn_seti (_safeArea, id_x, &hlt_i32, bounds.x + safeAreaInsets.x);
			hl_dyn_seti (_safeArea, id_y, &hlt_i32, bounds.y + safeAreaInsets.y);
			hl_dyn_seti (_safeArea, id_width, &hlt_i32, bounds.w - safeAreaInsets.x - safeAreaInsets.width);
			hl_dyn_seti (_safeArea, id_height, &hlt_i32, bounds.h - safeAreaInsets.y - safeAreaInsets.height);

			hl_dyn_setp (display, id_safeArea, &hlt_dynobj, _safeArea);

			float dpi = 72.0;
			#ifndef EMSCRIPTEN
			dpi *= SDL_GetDisplayContentScale (displayID);
			#endif
			hl_dyn_setf (display, id_dpi, dpi);

			SDL_DisplayOrientation orientation = SDL_GetCurrentDisplayOrientation (displayID);
			hl_dyn_seti (display, id_orientation, &hlt_i32, orientation);

			DisplayMode mode;

			SetDisplayMode (&mode, SDL_GetDesktopDisplayMode (displayID));

			vdynamic* _displayMode = (vdynamic*)hl_alloc_dynobj ();
			hl_dyn_seti (_displayMode, id_height, &hlt_i32, mode.height);
			hl_dyn_seti (_displayMode, id_pixelFormat, &hlt_i32, mode.pixelFormat);
			hl_dyn_seti (_displayMode, id_refreshRate, &hlt_i32, mode.refreshRate);
			hl_dyn_seti (_displayMode, id_width, &hlt_i32, mode.width);
			hl_dyn_setp (display, id_currentMode, &hlt_dynobj, _displayMode);

			int numDisplayModes = 0;
			SDL_DisplayMode** displayModes = SDL_GetFullscreenDisplayModes (displayID, &numDisplayModes);

			hl_varray* supportedModes = (hl_varray*)hl_alloc_array (&hlt_dynobj, numDisplayModes);
			vdynamic** supportedModesData = hl_aptr (supportedModes, vdynamic*);

			for (int i = 0; i < numDisplayModes; i++) {

				SetDisplayMode (&mode, displayModes ? displayModes[i] : NULL);

				vdynamic* _displayMode = (vdynamic*)hl_alloc_dynobj ();
				hl_dyn_seti (_displayMode, id_height, &hlt_i32, mode.height);
				hl_dyn_seti (_displayMode, id_pixelFormat, &hlt_i32, mode.pixelFormat);
				hl_dyn_seti (_displayMode, id_refreshRate, &hlt_i32, mode.refreshRate);
				hl_dyn_seti (_displayMode, id_width, &hlt_i32, mode.width);

				*supportedModesData++ = _displayMode;

			}

			if (displayModes) {

				SDL_free (displayModes);

			}

			hl_dyn_setp (display, id_supportedModes, &hlt_array, supportedModes);
			return display;

		}

	}


	int System::GetNumDisplays () {

		return GetSDLDisplayCount ();

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

		return stdioFile ? (FILE*)handle : NULL;

		#else

		return (FILE*)handle;

		#endif

	}


	int FILE_HANDLE::getLength () {

		#ifndef HX_WINDOWS

		System::GCEnterBlocking ();
		int size;

		if (stdioFile) {

			FILE* file = (FILE*)handle;
			long position = file ? ::ftell (file) : -1;

			if (position >= 0 && ::fseek (file, 0, SEEK_END) == 0) {

				size = (int)::ftell (file);
				::fseek (file, position, SEEK_SET);

			} else {

				size = -1;

			}

		} else {

			size = (int)SDL_GetIOSize ((SDL_IOStream*)handle);

		}

		System::GCExitBlocking ();
		return size;

		#else

		return 0;

		#endif

	}


	bool FILE_HANDLE::isFile () {

		#ifndef HX_WINDOWS

		return stdioFile;

		#else

		return true;

		#endif

	}


	int fclose (FILE_HANDLE *stream) {

		#ifndef HX_WINDOWS

		if (stream) {

			System::GCEnterBlocking ();
			int code = stream->stdioFile ? ::fclose ((FILE*)stream->handle) : (SDL_CloseIO ((SDL_IOStream*)stream->handle) ? 0 : EOF);
			delete stream;
			System::GCExitBlocking ();
			return code;

		}

		return 0;

		#else

		if (stream) {

			System::GCEnterBlocking ();
			int code = ::fclose ((FILE*)stream->handle);
			delete stream;
			System::GCExitBlocking ();
			return code;

		}

		return 0;

		#endif

	}


	FILE_HANDLE *fdopen (int fd, const char *mode) {

		#ifndef HX_WINDOWS

		System::GCEnterBlocking ();
		FILE* result = ::fdopen (fd, mode);
		System::GCExitBlocking ();

		if (result) {

			return new FILE_HANDLE (result, true);

		}

		return NULL;

		#else

		FILE* result;

		System::GCEnterBlocking ();
		result = ::fdopen (fd, mode);
		System::GCExitBlocking ();

		if (result) {

			return new FILE_HANDLE (result, true);

		}

		return NULL;

		#endif

	}


	FILE_HANDLE *fopen (const char *filename, const char *mode) {

		#ifndef HX_WINDOWS

		SDL_IOStream *result;

		System::GCEnterBlocking ();

		#ifdef HX_MACOS

		result = SDL_IOFromFile (filename, "rb");

		if (!result) {

			CFStringRef str = CFStringCreateWithCString (NULL, filename, kCFStringEncodingUTF8);
			CFURLRef path = CFBundleCopyResourceURL (CFBundleGetMainBundle (), str, NULL, NULL);
			CFRelease (str);

			if (path) {

				str = CFURLCopyPath (path);
				CFIndex maxSize = CFStringGetMaximumSizeForEncoding (CFStringGetLength (str), kCFStringEncodingUTF8) + 1;
				char *buffer = (char *)malloc (maxSize);

				if (CFStringGetCString (str, buffer, maxSize, kCFStringEncodingUTF8)) {

					result = SDL_IOFromFile (buffer, "rb");

				}

				free (buffer);
				CFRelease (str);
				CFRelease (path);

			}

		}
		#else
		result = SDL_IOFromFile (filename, mode);
		#endif

		System::GCExitBlocking ();

		if (result) {

			return new FILE_HANDLE (result);

		}

		return NULL;

		#else

		FILE* result;
		std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
		std::wstring* wfilename = new std::wstring (converter.from_bytes (filename));
		std::wstring* wmode = new std::wstring (converter.from_bytes (mode));

		System::GCEnterBlocking ();
		result = ::_wfopen (wfilename->c_str(), wmode->c_str());
		System::GCExitBlocking ();

		delete wfilename;
		delete wmode;

		if (result) {

			return new FILE_HANDLE (result, true);

		}

		return NULL;

		#endif

	}


	size_t fread (void *ptr, size_t size, size_t count, FILE_HANDLE *stream) {

		if (size == 0) return 0;

		size_t nmem;
		System::GCEnterBlocking ();

		#ifndef HX_WINDOWS

		if (stream && stream->stdioFile) {

			nmem = ::fread (ptr, size, count, (FILE*)stream->handle);

		} else {

			nmem = SDL_ReadIO (stream ? (SDL_IOStream*)stream->handle : NULL, ptr, size * count) / size;

		}

		#else

		nmem = ::fread (ptr, size, count, (FILE*)stream->handle);

		#endif

		System::GCExitBlocking ();
		return nmem;

	}


	int fseek (FILE_HANDLE *stream, long int offset, int origin) {

		int success;
		System::GCEnterBlocking ();

		#ifndef HX_WINDOWS

		if (stream && stream->stdioFile) {

			success = ::fseek ((FILE*)stream->handle, offset, origin);

		} else {

			success = SDL_SeekIO (stream ? (SDL_IOStream*)stream->handle : NULL, offset, (SDL_IOWhence)origin) < 0 ? -1 : 0;

		}

		#else

		success = ::fseek ((FILE*)stream->handle, offset, origin);

		#endif

		System::GCExitBlocking ();
		return success;

	}


	long int ftell (FILE_HANDLE *stream) {

		long int pos;
		System::GCEnterBlocking ();

		#ifndef HX_WINDOWS

		if (stream && stream->stdioFile) {

			pos = ::ftell ((FILE*)stream->handle);

		} else {

			pos = SDL_TellIO (stream ? (SDL_IOStream*)stream->handle : NULL);

		}

		#else

		pos = ::ftell ((FILE*)stream->handle);

		#endif

		System::GCExitBlocking ();
		return pos;

	}


	size_t fwrite (const void *ptr, size_t size, size_t count, FILE_HANDLE *stream) {

		if (size == 0) return 0;

		size_t nmem;
		System::GCEnterBlocking ();

		#ifndef HX_WINDOWS

		if (stream && stream->stdioFile) {

			nmem = ::fwrite (ptr, size, count, (FILE*)stream->handle);

		} else {

			nmem = SDL_WriteIO (stream ? (SDL_IOStream*)stream->handle : NULL, ptr, size * count) / size;

		}

		#else

		nmem = ::fwrite (ptr, size, count, (FILE*)stream->handle);

		#endif

		System::GCExitBlocking ();
		return nmem;

	}


}
