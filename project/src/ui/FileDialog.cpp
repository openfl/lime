#include <ui/FileDialog.h>
#include <stdio.h>
#include <cstdlib>
#include <cstring>
#include <sstream>

#include <tinyfiledialogs.h>


namespace lime {


	std::string* wstring_to_string (std::wstring* source) {

		if (!source) return NULL;

		int size = std::wcslen (source->c_str ());
		char* temp = (char*)malloc (size + 1);
		std::wcstombs (temp, source->c_str (), size);
		temp[size] = '\0';

		std::string* data = new std::string (temp);
		free (temp);
		return data;

	}


	std::wstring* FileDialog::OpenDirectory (std::wstring* title, std::wstring* filter, std::wstring* defaultPath) {

		// TODO: Filter?

		#ifdef HX_WINDOWS

		const wchar_t* path = tinyfd_selectFolderDialogW (title ? title->c_str () : 0, defaultPath ? defaultPath->c_str () : 0);

		if (path && std::wcslen(path) > 0) {

			std::wstring* _path = new std::wstring (path);
			return _path;

		}

		#else

		std::string* _title = wstring_to_string (title);
		//std::string* _filter = wstring_to_string (filter);
		std::string* _defaultPath = wstring_to_string (defaultPath);

		const char* path = tinyfd_selectFolderDialog (_title ? _title->c_str () : NULL, _defaultPath ? _defaultPath->c_str () : NULL);

		if (_title) delete _title;
		//if (_filter) delete _filter;
		if (_defaultPath) delete _defaultPath;

		if (path && std::strlen(path) > 0) {

			std::string _path = std::string (path);
			std::wstring* __path = new std::wstring (_path.begin (), _path.end ());
			return __path;

		}

		#endif

		return 0;

	}


	std::wstring* FileDialog::OpenFile (std::wstring* title, std::wstring* filter, std::wstring* defaultPath) {

		#ifdef HX_WINDOWS

		std::vector<std::wstring> filters_vec;
		if (filter) {
			std::wstring temp (L"*.");
			std::wstring line;
			std::wstringstream ss(*filter);
			while(std::getline(ss, line, L',')) {
				filters_vec.push_back(temp + line);
			}
		}

		const int numFilters = filter ? filters_vec.size() : 1;
		const wchar_t **filters = new const wchar_t*[numFilters];
		if (filter && numFilters > 0) {
			for (int index = 0; index < numFilters; index++) {
				filters[index] = const_cast<wchar_t*>(filters_vec[index].c_str());
			}
		} else {
			filters[0] = NULL;
		}

		const wchar_t* path = tinyfd_openFileDialogW (title ? title->c_str () : 0, defaultPath ? defaultPath->c_str () : 0, filter ? numFilters : 0, filter ? filters : NULL, NULL, 0);

		delete[] filters;

		if (path && std::wcslen(path) > 0) {

			std::wstring* _path = new std::wstring (path);
			return _path;

		}

		#else

		std::string* _title = wstring_to_string (title);
		std::string* _filter = wstring_to_string (filter);
		std::string* _defaultPath = wstring_to_string (defaultPath);

		std::vector<std::string> filters_vec;
		if (_filter) {
			std::string line;
			std::stringstream ss(*_filter);
			while(std::getline(ss, line, ',')) {
				line.insert (0, "*.");
				filters_vec.push_back(line);
			}
		}

		const int numFilters = _filter ? filters_vec.size() : 1;
		const char **filters = new const char*[numFilters];
		if (_filter && numFilters > 0) {
			for (int index = 0; index < numFilters; index++) {
				filters[index] = const_cast<char*>(filters_vec[index].c_str());
			}
		} else {
			filters[0] = NULL;
		}

		const char* path = tinyfd_openFileDialog (_title ? _title->c_str () : NULL, _defaultPath ? _defaultPath->c_str () : NULL, _filter ? numFilters : 0, _filter ? filters : NULL, NULL, 0);

		delete[] filters;

		if (_title) delete _title;
		if (_filter) delete _filter;
		if (_defaultPath) delete _defaultPath;

		if (path && std::strlen(path) > 0) {

			std::string _path = std::string (path);
			std::wstring* __path = new std::wstring (_path.begin (), _path.end ());
			return __path;

		}

		#endif

		return 0;

	}


	void FileDialog::OpenFiles (std::vector<std::wstring*>* files, std::wstring* title, std::wstring* filter, std::wstring* defaultPath) {

		std::wstring* __paths = 0;

		#ifdef HX_WINDOWS

		std::vector<std::wstring> filters_vec;
		if (filter) {
			std::wstring temp (L"*.");
			std::wstring line;
			std::wstringstream ss(*filter);
			while(std::getline(ss, line, L',')) {
				filters_vec.push_back(temp + line);
			}
		}

		const int numFilters = filter ? filters_vec.size() : 1;
		const wchar_t **filters = new const wchar_t*[numFilters];
		if (filter && numFilters > 0) {
			for (int index = 0; index < numFilters; index++) {
				filters[index] = const_cast<wchar_t*>(filters_vec[index].c_str());
			}
		} else {
			filters[0] = NULL;
		}

		const wchar_t* paths = tinyfd_openFileDialogW (title ? title->c_str () : 0, defaultPath ? defaultPath->c_str () : 0, filter ? numFilters : 0, filter ? filters : NULL, NULL, 1);

		delete[] filters;

		if (paths) {

			__paths = new std::wstring (paths);

		}

		#else

		std::string* _title = wstring_to_string (title);
		std::string* _filter = wstring_to_string (filter);
		std::string* _defaultPath = wstring_to_string (defaultPath);

		std::vector<std::string> filters_vec;
		if (_filter) {
			std::string line;
			std::stringstream ss(*_filter);
			while(std::getline(ss, line, ',')) {
				line.insert (0, "*.");
				filters_vec.push_back(line);
			}
		}

		const int numFilters = _filter ? filters_vec.size() : 1;
		const char **filters = new const char*[numFilters];
		if (_filter && numFilters > 0) {
			for (int index = 0; index < numFilters; index++) {
				filters[index] = const_cast<char*>(filters_vec[index].c_str());
			}
		} else {
			filters[0] = NULL;
		}

		const char* paths = tinyfd_openFileDialog (_title ? _title->c_str () : NULL, _defaultPath ? _defaultPath->c_str () : NULL, _filter ? numFilters : 0, _filter ? filters : NULL, NULL, 1);

		delete[] filters;

		if (_title) delete _title;
		if (_filter) delete _filter;
		if (_defaultPath) delete _defaultPath;

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


	std::wstring* FileDialog::SaveFile (std::wstring* title, std::wstring* filter, std::wstring* defaultPath) {

		#ifdef HX_WINDOWS

		std::wstring temp (L"*.");
		const wchar_t* filters[] = { filter ? (temp + *filter).c_str () : NULL };

		const wchar_t* path = tinyfd_saveFileDialogW (title ? title->c_str () : 0, defaultPath ? defaultPath->c_str () : 0, filter ? 1 : 0, filter ? filters : NULL, NULL);

		if (path && std::wcslen(path) > 0) {

			std::wstring* _path = new std::wstring (path);
			return _path;

		}

		#else

		std::string* _title = wstring_to_string (title);
		std::string* _filter = wstring_to_string (filter);
		std::string* _defaultPath = wstring_to_string (defaultPath);

		const char* filters[] = { NULL };

		if (_filter) {

			_filter->insert (0, "*.");
			filters[0] = _filter->c_str ();

		}

		const char* path = tinyfd_saveFileDialog (_title ? _title->c_str () : NULL, _defaultPath ? _defaultPath->c_str () : NULL, _filter ? 1 : 0, _filter ? filters : NULL, NULL);

		if (_title) delete _title;
		if (_filter) delete _filter;
		if (_defaultPath) delete _defaultPath;

		if (path && std::strlen(path) > 0) {

			std::string _path = std::string (path);
			std::wstring* __path = new std::wstring (_path.begin (), _path.end ());
			return __path;

		}

		#endif

		return 0;

	}


}
