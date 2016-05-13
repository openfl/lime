#include <ui/FileDialog.h>
#include <nfd.h>
#include <stdio.h>


namespace lime {
	
	
	const char* FileDialog::OpenDirectory (const char* filter, const char* defaultPath) {
		
		nfdchar_t *savePath = 0;
		nfdresult_t result = NFD_OpenDirectoryDialog (filter, defaultPath, &savePath);
		
		switch (result) {
			
			case NFD_OKAY:
				
				return savePath;
				break;
			
			case NFD_CANCEL:
				
				break;
			
			default:
				
				printf ("Error: %s\n", NFD_GetError ());
				break;
			
		}
		
		return savePath;
		
	}
	
	
	const char* FileDialog::OpenFile (const char* filter, const char* defaultPath) {
		
		nfdchar_t *savePath = 0;
		nfdresult_t result = NFD_OpenDialog (filter, defaultPath, &savePath);
		
		switch (result) {
			
			case NFD_OKAY:
				
				return savePath;
				break;
			
			case NFD_CANCEL:
				
				break;
			
			default:
				
				printf ("Error: %s\n", NFD_GetError ());
				break;
			
		}
		
		return savePath;
		
	}
	
	
	void FileDialog::OpenFiles (std::vector<const char*>* files, const char* filter, const char* defaultPath) {
		
		nfdpathset_t pathSet;
		nfdresult_t result = NFD_OpenDialogMultiple (filter, defaultPath, &pathSet);
		
		switch (result) {
			
			case NFD_OKAY:
			{
				for (int i = 0; i < NFD_PathSet_GetCount (&pathSet); i++) {
					
					files->push_back (NFD_PathSet_GetPath (&pathSet, i));
					
				}
				
				NFD_PathSet_Free (&pathSet);
				break;
			}
			
			case NFD_CANCEL:
				
				break;
			
			default:
				
				printf ("Error: %s\n", NFD_GetError ());
				break;
			
		}
		
	}
	
	
	const char* FileDialog::SaveFile (const char* filter, const char* defaultPath) {
		
		nfdchar_t *savePath = 0;
		nfdresult_t result = NFD_SaveDialog (filter, defaultPath, &savePath);
		
		switch (result) {
			
			case NFD_OKAY:
				
				return savePath;
				break;
			
			case NFD_CANCEL:
				
				break;
			
			default:
				
				printf ("Error: %s\n", NFD_GetError ());
				break;
			
		}
		
		return savePath;
		
	}
	
	
}