#ifndef LIME_UI_FILE_DIALOG_H
#define LIME_UI_FILE_DIALOG_H


#include <vector>


namespace lime {
	
	
	class FileDialog {
		
		public:
			
			static const char* OpenFile (const char* filter = NULL, const char* defaultPath = NULL);
			static void OpenFiles (std::vector<const char*>* files, const char* filter = NULL, const char* defaultPath = NULL);
			static const char* SaveFile (const char* filter = NULL, const char* defaultPath = NULL);
		
	};
	
	
}


#endif