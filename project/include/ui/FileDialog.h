#ifndef LIME_UI_FILE_DIALOG_H
#define LIME_UI_FILE_DIALOG_H


#include <vector>


namespace lime {
	
	
	class FileDialog {
		
		public:
			
			static const char* OpenDirectory (const char* filter = 0, const char* defaultPath = 0);
			static const char* OpenFile (const char* filter = 0, const char* defaultPath = 0);
			static void OpenFiles (std::vector<const char*>* files, const char* filter = 0, const char* defaultPath = 0);
			static const char* SaveFile (const char* filter = 0, const char* defaultPath = 0);
		
	};
	
	
}


#endif