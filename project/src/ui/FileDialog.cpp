#include <ui/FileDialog.h>
#include <stdio.h>
#include <cstdlib>
#include <cstring>
#include <sstream>

#include <tinyfiledialogs.h>

#ifdef HX_WINDOWS
#define tinyfd_selectFolderDialog tinyfd_selectFolderDialogW
#define tinyfd_openFileDialog tinyfd_openFileDialogW
#define tinyfd_saveFileDialog tinyfd_saveFileDialogW

#define FD_STR(str) L##str
#else
#define FD_STR(str) str
#endif

using char_t = lime::FileDialog::char_t;
using string_t = std::basic_string<char_t>;

namespace lime {

	static bool is_null_or_empty (const char_t* str) {
		return str == nullptr || str[0] == 0;
	}

	static string_t normalize_filter (const string_t& filter) {

		if (filter.empty () || filter.find (FD_STR('*')) != string_t::npos || filter.find (FD_STR('?')) != string_t::npos) {

			return filter;

		}

		if (filter[0] == FD_STR('.')) {

			return string_t (FD_STR("*")) + filter;

		}

		return string_t (FD_STR("*.")) + filter;

	}

	static std::vector<string_t> normalize_filters (const char_t* filter) {

		std::vector<string_t> filters;

		if (filter) {

			string_t line;
			std::basic_stringstream<char_t> ss (filter);

			while (std::getline (ss, line, FD_STR(','))) {

				filters.push_back (normalize_filter (line));

			}

		}

		return filters;

	}

	const char_t* FileDialog::OpenDirectory (const char_t* title, const char_t* filter, const char_t* defaultPath) {

		// TODO: Filter?

		const char_t* path = tinyfd_selectFolderDialog(title, defaultPath);

		if (!is_null_or_empty(path)) {

			return path;

		}

		return 0;

	}


	const char_t* FileDialog::OpenFile (const char_t* title, const char_t* filter, const char_t* defaultPath) {

		std::vector<string_t> filters_vec = normalize_filters (filter);

		const int numFilters = filters_vec.size ();
		const char_t **filters = numFilters > 0 ? new const char_t*[numFilters] : NULL;
		if (numFilters > 0) {
			for (int index = 0; index < numFilters; index++) {
				filters[index] = filters_vec[index].c_str();
			}
		}

		const char_t* path = tinyfd_openFileDialog (title, defaultPath, numFilters, filters, NULL, 0);

		delete[] filters;

		if (!is_null_or_empty(path)) {

			return path;

		}

		return 0;

	}


	std::vector<FileDialog::string_view> FileDialog::OpenFiles (const char_t* title, const char_t* filter, const char_t* defaultPath) {
		std::vector<string_view> files;

		std::vector<string_t> filters_vec = normalize_filters (filter);

		const int numFilters = filters_vec.size ();
		const char_t **filters = numFilters > 0 ? new const char_t*[numFilters] : NULL;
		if (numFilters > 0) {
			for (int index = 0; index < numFilters; index++) {
				filters[index] = filters_vec[index].c_str();
			}
		}

		const char_t* paths = tinyfd_openFileDialog (title, defaultPath, numFilters, filters, NULL, 1);

		delete[] filters;

		if (!is_null_or_empty(paths)) {

			char_t sep = FD_STR('|');

			const char_t* start = paths,
						* cur = paths;

			while (*cur) {
				if (*cur == sep) {
					files.emplace_back(start, cur - start);
					start = cur + 1;
				}

				cur++;
			}

			files.emplace_back(start, cur - start);

		}

		return files;

	}


	const char_t* FileDialog::SaveFile (const char_t* title, const char_t* filter, const char_t* defaultPath) {

		std::vector<string_t> filters_vec = normalize_filters (filter);
		const int numFilters = filters_vec.size () > 0 ? 1 : 0;
		const char_t* filters[] = { numFilters > 0 ? filters_vec[0].c_str () : NULL };

		const char_t* path = tinyfd_saveFileDialog (title, defaultPath, numFilters, numFilters > 0 ? filters : NULL, NULL);

		if (!is_null_or_empty(path)) {

			return path;

		}

		return 0;

	}


}
