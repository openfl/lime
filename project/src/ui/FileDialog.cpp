#include <ui/FileDialog.h>
#include <stdio.h>
#include <cstdlib>

#include <tinyfiledialogs.h>


namespace lime {
	
	
	std::wstring* FileDialog::OpenDirectory (std::wstring* filter, std::wstring* defaultPath) {
		
		// TODO: Filters
		
		#ifdef HX_WINDOWS
		
		const wchar_t* path = tinyfd_selectFolderDialogW (L"", defaultPath ? defaultPath->c_str () : 0);
		
		if (path) {
			
			std::wstring* _path = new std::wstring (path);
			return _path;
			
		}
		
		#else
		
		char* _defaultPath = 0;
		
		if (defaultPath) {
			
			int size = std::wcslen (defaultPath->c_str ());
			char* _defaultPath = (char*)malloc (size);
			std::wcstombs (_defaultPath, defaultPath->c_str (), size);
			
		}
		
		const char* path = tinyfd_selectFolderDialog ("", _defaultPath);
		
		if (_defaultPath) free (_defaultPath);
		
		if (path) {
			
			std::string _path = std::string (path);
			std::wstring* __path = new std::wstring (_path.begin (), _path.end ());
			return __path;
			
		}
		
		#endif
		
		return 0;
		
	}
	
	
	std::wstring* FileDialog::OpenFile (std::wstring* filter, std::wstring* defaultPath) {
		
		// TODO: Filters
		
		#ifdef HX_WINDOWS
		
		const wchar_t* path = tinyfd_openFileDialogW (L"", defaultPath ? defaultPath->c_str () : 0, 0, NULL, NULL, 0);
		
		if (path) {
			
			std::wstring* _path = new std::wstring (path);
			return _path;
			
		}
		
		#else
		
		char* _defaultPath = 0;
		
		if (defaultPath) {
			
			int size = std::wcslen (defaultPath->c_str ());
			char* _defaultPath = (char*)malloc (size);
			std::wcstombs (_defaultPath, defaultPath->c_str (), size);
			
		}
		
		const char* path = tinyfd_openFileDialog ("", _defaultPath, 0, NULL, NULL, 0);
		
		if (_defaultPath) free (_defaultPath);
		
		if (path) {
			
			std::string _path = std::string (path);
			std::wstring* __path = new std::wstring (_path.begin (), _path.end ());
			return __path;
			
		}
		
		#endif
		
		return 0;
		
	}
	
	
	void FileDialog::OpenFiles (std::vector<std::wstring*>* files, std::wstring* filter, std::wstring* defaultPath) {
		
		// TODO: Filters
		
		std::wstring* __paths = 0;
		
		#ifdef HX_WINDOWS
		
		const wchar_t* paths = tinyfd_openFileDialogW (L"", defaultPath ? defaultPath->c_str () : 0, 0, NULL, NULL, 1);
		
		if (paths) {
			
			__paths = new std::wstring (paths);
			
		}
		
		#else
		
		char* _defaultPath = 0;
		
		if (defaultPath) {
			
			int size = std::wcslen (defaultPath->c_str ());
			char* _defaultPath = (char*)malloc (size);
			std::wcstombs (_defaultPath, defaultPath->c_str (), size);
			
		}
		
		const char* paths = tinyfd_openFileDialog ("", _defaultPath, 0, NULL, NULL, 1);
		
		if (_defaultPath) free (_defaultPath);
		
		if (paths) {
			
			std::string _paths = std::string (paths);
			__paths = new std::wstring (_paths.begin (), _paths.end ());
			
		}
		
		#endif
		
		if (__paths) {
			
			std::wstring sep = L"|";
			
			std::size_t start = 0, end = 0;
			
			while ((end = __paths->find (sep, start)) != std::wstring::npos) {
				
				files->push_back (new std::wstring (__paths->substr (start, end - start).c_str ()));
				start = end + 1;
				
			}
			
			files->push_back (new std::wstring (__paths->substr (start).c_str ()));
			
		}
		
	}
	
	
	std::wstring* FileDialog::SaveFile (std::wstring* filter, std::wstring* defaultPath) {
		
		// TODO: Filters
		
		#ifdef HX_WINDOWS
		
		const wchar_t* path = tinyfd_saveFileDialogW (L"", defaultPath ? defaultPath->c_str () : 0, 0, NULL, NULL);
		
		if (path) {
			
			std::wstring* _path = new std::wstring (path);
			return _path;
			
		}
		
		#else
		
		char* _defaultPath = 0;
		
		if (defaultPath) {
			
			int size = std::wcslen (defaultPath->c_str ());
			char* _defaultPath = (char*)malloc (size);
			std::wcstombs (_defaultPath, defaultPath->c_str (), size);
			
		}
		
		const char* path = tinyfd_saveFileDialog ("", _defaultPath, 0, NULL, NULL);
		
		if (_defaultPath) free (_defaultPath);
		
		if (path) {
			
			std::string _path = std::string (path);
			std::wstring* __path = new std::wstring (_path.begin (), _path.end ());
			return __path;
			
		}
		
		#endif
		
		return 0;
		
	}
	
	
}