#ifndef LIME_UI_FILE_DIALOG_H
#define LIME_UI_FILE_DIALOG_H


#include <string>
#include <vector>


namespace lime {


	class FileDialog {

		public:

			static std::wstring* OpenDirectory (std::wstring* title = 0, std::wstring* filter = 0, std::wstring* defaultPath = 0);
			static std::wstring* OpenFile (std::wstring* title = 0, std::wstring* filter = 0, std::wstring* defaultPath = 0);
			static void OpenFiles (std::vector<std::wstring*>* files, std::wstring* title = 0, std::wstring* filter = 0, std::wstring* defaultPath = 0);
			static std::wstring* SaveFile (std::wstring* title = 0, std::wstring* filter = 0, std::wstring* defaultPath = 0);

	};


}


#endif