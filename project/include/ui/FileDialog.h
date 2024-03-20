#ifndef LIME_UI_FILE_DIALOG_H
#define LIME_UI_FILE_DIALOG_H


#include <string>
#include <vector>


namespace lime {


	class FileDialog {

		public:

		#ifdef HX_WINDOWS
			// Path separator used by OpenFiles
			static const wchar_t PATH_SEPARATOR = L'|';

			static const wchar_t* OpenDirectory (const wchar_t* title = 0, const wchar_t* filter = 0, const wchar_t* defaultPath = 0);
			static const wchar_t* OpenFile (const wchar_t* title = 0, const wchar_t* filter = 0, const wchar_t* defaultPath = 0);
			static const wchar_t* OpenFiles (const wchar_t* title = 0, const wchar_t* filter = 0, const wchar_t* defaultPath = 0);
			static const wchar_t* SaveFile (const wchar_t* title = 0, const wchar_t* filter = 0, const wchar_t* defaultPath = 0);
		#else
			// Path separator used by OpenFiles
			static const char PATH_SEPARATOR = '|';

			static const char* OpenDirectory (const char* title = 0, const char* filter = 0, const char* defaultPath = 0);
			static const char* OpenFile (const char* title = 0, const char* filter = 0, const char* defaultPath = 0);
			static const char* OpenFiles (const char* title = 0, const char* filter = 0, const char* defaultPath = 0);
			static const char* SaveFile (const char* title = 0, const char* filter = 0, const char* defaultPath = 0);
		#endif

	};


}


#endif