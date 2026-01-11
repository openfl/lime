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

#include <SDL.h>
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


	const char* Clipboard::GetText () {

		return SDL_GetClipboardText ();

	}


	bool Clipboard::HasText () {

		return SDL_HasClipboardText ();

	}


	bool Clipboard::SetText (const char* text) {

		return (SDL_SetClipboardText (text) == 0);

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


	std::wstring* System::GetDirectory (SystemDirectory type, const char* company, const char* title) {

		std::wstring* result = 0;
		System::GCEnterBlocking ();

		switch (type) {

			case APPLICATION: {

				char* path = SDL_GetBasePath ();

				if (path != nullptr) {

					wstring_convert converter;
					result = new std::wstring (converter.from_bytes(path));
					SDL_free (path);

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

			value display = alloc_empty_object ();
			alloc_field (display, id_name, alloc_string (SDL_GetDisplayName (id)));

			SDL_Rect bounds = { 0, 0, 0, 0 };
			SDL_GetDisplayBounds (id, &bounds);
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
			SDL_GetDisplayDPI (id, &dpi, NULL, NULL);
			#endif
			alloc_field (display, id_dpi, alloc_float (dpi));

			SDL_DisplayOrientation orientation = SDL_GetDisplayOrientation(id);
			alloc_field (display, id_orientation, alloc_int (orientation));

			SDL_DisplayMode displayMode = { SDL_PIXELFORMAT_UNKNOWN, 0, 0, 0, 0 };
			DisplayMode mode;

			SDL_GetDesktopDisplayMode (id, &displayMode);

			mode.height = displayMode.h;

			switch (displayMode.format) {

				case SDL_PIXELFORMAT_ARGB8888:

					mode.pixelFormat = ARGB32;
					break;

				case SDL_PIXELFORMAT_BGRA8888:
				case SDL_PIXELFORMAT_BGRX8888:

					mode.pixelFormat = BGRA32;
					break;

				default:

					mode.pixelFormat = RGBA32;

			}

			mode.refreshRate = displayMode.refresh_rate;
			mode.width = displayMode.w;

			alloc_field (display, id_currentMode, (value)mode.Value ());

			int numDisplayModes = SDL_GetNumDisplayModes (id);
			value supportedModes = alloc_array (numDisplayModes);

			for (int i = 0; i < numDisplayModes; i++) {

				SDL_GetDisplayMode (id, i, &displayMode);

				mode.height = displayMode.h;

				switch (displayMode.format) {

					case SDL_PIXELFORMAT_ARGB8888:

						mode.pixelFormat = ARGB32;
						break;

					case SDL_PIXELFORMAT_BGRA8888:
					case SDL_PIXELFORMAT_BGRX8888:

						mode.pixelFormat = BGRA32;
						break;

					default:

						mode.pixelFormat = RGBA32;

				}

				mode.refreshRate = displayMode.refresh_rate;
				mode.width = displayMode.w;

				val_array_set_i (supportedModes, i, (value)mode.Value ());

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

			vdynamic* display = (vdynamic*)hl_alloc_dynobj ();

			const char* displayName = SDL_GetDisplayName (id);
			char* _displayName = (char*)malloc(strlen(displayName) + 1);
			strcpy (_displayName, displayName);
			hl_dyn_setp (display, id_name, &hlt_bytes, _displayName);

			SDL_Rect bounds = { 0, 0, 0, 0 };
			SDL_GetDisplayBounds (id, &bounds);

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
			SDL_GetDisplayDPI (id, &dpi, NULL, NULL);
			#endif
			hl_dyn_setf (display, id_dpi, dpi);

			SDL_DisplayOrientation orientation = SDL_GetDisplayOrientation(id);
			hl_dyn_seti (display, id_orientation, &hlt_i32, orientation);

			SDL_DisplayMode displayMode = { SDL_PIXELFORMAT_UNKNOWN, 0, 0, 0, 0 };
			DisplayMode mode;

			SDL_GetDesktopDisplayMode (id, &displayMode);

			mode.height = displayMode.h;

			switch (displayMode.format) {

				case SDL_PIXELFORMAT_ARGB8888:

					mode.pixelFormat = ARGB32;
					break;

				case SDL_PIXELFORMAT_BGRA8888:
				case SDL_PIXELFORMAT_BGRX8888:

					mode.pixelFormat = BGRA32;
					break;

				default:

					mode.pixelFormat = RGBA32;

			}

			mode.refreshRate = displayMode.refresh_rate;
			mode.width = displayMode.w;

			vdynamic* _displayMode = (vdynamic*)hl_alloc_dynobj ();
			hl_dyn_seti (_displayMode, id_height, &hlt_i32, mode.height);
			hl_dyn_seti (_displayMode, id_pixelFormat, &hlt_i32, mode.pixelFormat);
			hl_dyn_seti (_displayMode, id_refreshRate, &hlt_i32, mode.refreshRate);
			hl_dyn_seti (_displayMode, id_width, &hlt_i32, mode.width);
			hl_dyn_setp (display, id_currentMode, &hlt_dynobj, _displayMode);

			int numDisplayModes = SDL_GetNumDisplayModes (id);

			hl_varray* supportedModes = (hl_varray*)hl_alloc_array (&hlt_dynobj, numDisplayModes);
			vdynamic** supportedModesData = hl_aptr (supportedModes, vdynamic*);

			for (int i = 0; i < numDisplayModes; i++) {

				SDL_GetDisplayMode (id, i, &displayMode);

				mode.height = displayMode.h;

				switch (displayMode.format) {

					case SDL_PIXELFORMAT_ARGB8888:

						mode.pixelFormat = ARGB32;
						break;

					case SDL_PIXELFORMAT_BGRA8888:
					case SDL_PIXELFORMAT_BGRX8888:

						mode.pixelFormat = BGRA32;
						break;

					default:

						mode.pixelFormat = RGBA32;

				}

				mode.refreshRate = displayMode.refresh_rate;
				mode.width = displayMode.w;

				vdynamic* _displayMode = (vdynamic*)hl_alloc_dynobj ();
				hl_dyn_seti (_displayMode, id_height, &hlt_i32, mode.height);
				hl_dyn_seti (_displayMode, id_pixelFormat, &hlt_i32, mode.pixelFormat);
				hl_dyn_seti (_displayMode, id_refreshRate, &hlt_i32, mode.refreshRate);
				hl_dyn_seti (_displayMode, id_width, &hlt_i32, mode.width);

				*supportedModesData++ = _displayMode;

			}

			hl_dyn_setp (display, id_supportedModes, &hlt_array, supportedModes);
			return display;

		}

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
			{
				#ifdef HAVE_STDIO_H
				return ((SDL_RWops*)handle)->hidden.stdio.fp;
				#else
				#error Lime requires HAVE_STDIO_H
				#endif
			}
			case SDL_RWOPS_JNIFILE:
			{
				#ifdef ANDROID
				System::GCEnterBlocking ();
				int fd;
				off_t outStart;
				off_t outLength;
				fd = AAsset_openFileDescriptor ((AAsset*)(((SDL_RWops*)handle)->hidden.androidio.asset), &outStart, &outLength);
				FILE* file = ::fdopen (fd, "rb");
				::fseek (file, outStart, 0);
				System::GCExitBlocking ();
				return file;
				#endif
			}

		}

		return NULL;

		#else

		return (FILE*)handle;

		#endif

	}


	int FILE_HANDLE::getLength () {

		#ifndef HX_WINDOWS

		System::GCEnterBlocking ();
		int size = SDL_RWsize (((SDL_RWops*)handle));
		System::GCExitBlocking ();
		return size;

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

			System::GCEnterBlocking ();
			int code = SDL_RWclose ((SDL_RWops*)stream->handle);
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
		FILE* fp = ::fdopen (fd, mode);
		SDL_RWops *result = SDL_RWFromFP (fp, SDL_TRUE);
		System::GCExitBlocking ();

		if (result) {

			return new FILE_HANDLE (result);

		}

		return NULL;

		#else

		FILE* result;

		System::GCEnterBlocking ();
		result = ::fdopen (fd, mode);
		System::GCExitBlocking ();

		if (result) {

			return new FILE_HANDLE (result);

		}

		return NULL;

		#endif

	}


	FILE_HANDLE *fopen (const char *filename, const char *mode) {

		#ifndef HX_WINDOWS

		SDL_RWops *result;

		System::GCEnterBlocking ();

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

			return new FILE_HANDLE (result);

		}

		return NULL;

		#endif

	}


	size_t fread (void *ptr, size_t size, size_t count, FILE_HANDLE *stream) {

		size_t nmem;
		System::GCEnterBlocking ();

		#ifndef HX_WINDOWS

		nmem = SDL_RWread (stream ? (SDL_RWops*)stream->handle : NULL, ptr, size, count);

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

		success = SDL_RWseek (stream ? (SDL_RWops*)stream->handle : NULL, offset, origin);

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

		pos = SDL_RWtell (stream ? (SDL_RWops*)stream->handle : NULL);

		#else

		pos = ::ftell ((FILE*)stream->handle);

		#endif

		System::GCExitBlocking ();
		return pos;

	}


	size_t fwrite (const void *ptr, size_t size, size_t count, FILE_HANDLE *stream) {

		size_t nmem;
		System::GCEnterBlocking ();

		#ifndef HX_WINDOWS

		nmem = SDL_RWwrite (stream ? (SDL_RWops*)stream->handle : NULL, ptr, size, count);

		#else

		nmem = ::fwrite (ptr, size, count, (FILE*)stream->handle);

		#endif

		System::GCExitBlocking ();
		return nmem;

	}


}
