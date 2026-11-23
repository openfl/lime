#include <system/System.h>

#if defined (HX_WINDOWS)
#include <windows.h>
#include <string>
#else
#include <sys/stat.h>
#include <sys/statvfs.h>
#endif


namespace lime {


	#if defined (HX_WINDOWS)
	static std::wstring ToWide (const char* text) {

		int length = MultiByteToWideChar (CP_UTF8, 0, text, -1, NULL, 0);
		if (length <= 0) return std::wstring ();

		std::wstring result (length, L'\0');
		MultiByteToWideChar (CP_UTF8, 0, text, -1, &result[0], length);
		result.resize (length - 1);
		return result;

	}
	#endif


	double System::GetAvailableSpace (const char* path) {

		if (!path || !path[0]) return -1;

		#if defined (HX_WINDOWS)
		// GetDiskFreeSpaceEx takes a folder, so a file's folder, or the nearest one that exists, is asked
		std::wstring folder = ToWide (path);

		while (!folder.empty ()) {

			ULARGE_INTEGER available;

			if (GetDiskFreeSpaceExW (folder.c_str (), &available, NULL, NULL)) {

				return (double)available.QuadPart;

			}

			// Up to the folder holding it, keeping the separator of a drive or root folder
			size_t separator = folder.find_last_of (L"\\/");
			if (separator == std::wstring::npos) break;

			std::wstring parent = folder.substr (0, (separator == 0 || folder[separator - 1] == L':') ? separator + 1 : separator);
			if (parent == folder) break;
			folder = parent;

		}

		return -1;
		#else
		// The space this user can use, which leaves out what is kept for the system
		struct statvfs info;
		if (statvfs (path, &info) != 0) return -1;
		return (double)info.f_bavail * (double)info.f_frsize;
		#endif

	}


	bool System::IsSymbolicLink (const char* path) {

		if (!path || !path[0]) return false;

		#if defined (HX_WINDOWS)
		// Junctions and other reparse points are links to Windows, as they are to AIR
		DWORD attributes = GetFileAttributesW (ToWide (path).c_str ());
		return attributes != INVALID_FILE_ATTRIBUTES && (attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0;
		#else
		struct stat info;
		return lstat (path, &info) == 0 && S_ISLNK (info.st_mode);
		#endif

	}


}
