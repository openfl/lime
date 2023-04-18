#include <ui/FileDialog.h>
#include <stdio.h>
#include <cstdlib>
#include <cstring>
#include <sstream>

#include <tinyfiledialogs.h>


namespace lime {

	template<typename T>
	static bool is_empty (const T* str) {
		return str[0] == 0;
	}

	#ifdef HX_WINDOWS

	const wchar_t* FileDialog::OpenDirectory (const wchar_t* title, const wchar_t* filter, const wchar_t* defaultPath) {

		// TODO: Filter?

		const wchar_t* path = tinyfd_selectFolderDialogW (title, defaultPath);

		if (path && !is_empty(path)) {

			return path;

		}

		return 0;

	}

	const wchar_t* FileDialog::OpenFile (const wchar_t* title, const wchar_t* filter, const wchar_t* defaultPath) {

		std::vector<std::wstring> filters_vec;
		if (filter) {
			std::wstring temp (L"*.");
			std::wstring line;
			std::wstringstream ss(filter);
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

		const wchar_t* path = tinyfd_openFileDialogW (title, defaultPath, filter ? numFilters : 0, filter ? filters : NULL, NULL, 0);

		delete[] filters;

		if (path && !is_empty(path)) {

			return path;

		}

		return 0;

	}


	const wchar_t* FileDialog::OpenFiles (const wchar_t* title, const wchar_t* filter, const wchar_t* defaultPath) {

		std::vector<std::wstring> filters_vec;
		if (filter) {
			std::wstring temp (L"*.");
			std::wstring line;
			std::wstringstream ss(filter);
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

		const wchar_t* paths = tinyfd_openFileDialogW (title, defaultPath, filter ? numFilters : 0, filter ? filters : NULL, NULL, 1);

		delete[] filters;

		if (paths && !is_empty(paths)) {

			return paths;

		}

		return 0;

	}


	const wchar_t* FileDialog::SaveFile (const wchar_t* title, const wchar_t* filter, const wchar_t* defaultPath) {

		const wchar_t* filters[] = { NULL };

		std::wstring filter_string = L"*.";
		if (filter) {
			filter_string.append(filter);
			filters[0] = filter_string.c_str();
		}

		const wchar_t* path = tinyfd_saveFileDialogW (title, defaultPath, filter ? 1 : 0, filter ? filters : NULL, NULL);

		if (path && !is_empty(path)) {

			return path;

		}

		return 0;

	}

	#else

	const char* FileDialog::OpenDirectory (const char* title, const char* filter, const char* defaultPath) {

		// TODO: Filter?

		const char* path = tinyfd_selectFolderDialog (title, defaultPath);

		if (path && !is_empty(path)) {

			return path;

		}

		return 0;

	}

	const char* FileDialog::OpenFile (const char* title, const char* filter, const char* defaultPath) {

		std::vector<std::string> filters_vec;
		if (filter) {
			std::string line;
			std::stringstream ss(filter);
			while(std::getline(ss, line, ',')) {
				line.insert (0, "*.");
				filters_vec.push_back(line);
			}
		}

		const int numFilters = filter ? filters_vec.size() : 1;
		const char **filters = new const char*[numFilters];
		if (filter && numFilters > 0) {
			for (int index = 0; index < numFilters; index++) {
				filters[index] = const_cast<char*>(filters_vec[index].c_str());
			}
		} else {
			filters[0] = NULL;
		}

		const char* path = tinyfd_openFileDialog (title, defaultPath, filter ? numFilters : 0, filter ? filters : NULL, NULL, 0);

		delete[] filters;

		if (path && !is_empty(path)) {

			return path;

		}

		return 0;

	}


	const char* FileDialog::OpenFiles (const char* title, const char* filter, const char* defaultPath) {

		std::vector<std::string> filters_vec;
		if (filter) {
			std::string line;
			std::stringstream ss(filter);
			while(std::getline(ss, line, ',')) {
				line.insert (0, "*.");
				filters_vec.push_back(line);
			}
		}

		const int numFilters = filter ? filters_vec.size() : 1;
		const char **filters = new const char*[numFilters];
		if (filter && numFilters > 0) {
			for (int index = 0; index < numFilters; index++) {
				filters[index] = const_cast<char*>(filters_vec[index].c_str());
			}
		} else {
			filters[0] = NULL;
		}

		const char* paths = tinyfd_openFileDialog (title, defaultPath, filter ? numFilters : 0, filter ? filters : NULL, NULL, 1);

		delete[] filters;

		if (paths && !is_empty(paths)) {

			return paths;

		}

		return 0;
	}


	const char* FileDialog::SaveFile (const char* title, const char* filter, const char* defaultPath) {

		const char* filters[] = { NULL };

		std::string filter_string = "*.";
		if (filter) {
			filter_string.append(filter);
			filters[0] = filter_string.c_str();
		}

		const char* path = tinyfd_saveFileDialog (title, defaultPath, filter ? 1 : 0, filter ? filters : NULL, NULL);

		if (path && !is_empty(path)) {

			return path;

		}

		return 0;

	}

	#endif
}
