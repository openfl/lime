#ifndef LIME_UI_FILE_DIALOG_H
#define LIME_UI_FILE_DIALOG_H


#include <string>
#include <vector>


namespace lime {


	// Functions in this class return pointers to externally owned memory, which will be reused automatically
	// for future dialogs and should not be freed.
	class FileDialog {

		public:

#ifdef HX_WINDOWS
			using char_t = wchar_t;
#else
			using char_t = char;
#endif

			static const char_t* OpenDirectory(const char_t* title = nullptr, const char_t* filter = nullptr, const char_t* defaultPath = nullptr);
			static const char_t* OpenFile(const char_t* title = nullptr, const char_t* filter = nullptr, const char_t* defaultPath = nullptr);

			// Use actual string view once we can use c++17
			class string_view {
			public:
				string_view(const char_t* c_str, size_t length) : c_str(c_str), length(length) {}

				const char_t* data() const { return c_str; }
				size_t size() const { return length; }

			private:
				const char_t* c_str;
				size_t length;
			};

			static std::vector<string_view> OpenFiles(const char_t* title = nullptr, const char_t* filter = nullptr, const char_t* defaultPath = nullptr);
			static const char_t* SaveFile(const char_t* title = nullptr, const char_t* filter = nullptr, const char_t* defaultPath = nullptr);

	};


}


#endif
