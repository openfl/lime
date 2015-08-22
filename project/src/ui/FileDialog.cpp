#include <ui/FileDialog.h>
#include <nfd.h>


namespace lime {
	
	
	const char* FileDialog::OpenFile (const char* filter, const char* defaultPath) {
		
		nfdchar_t *savePath = NULL;
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
	
	
	void FileDialog::OpenFiles (QuickVec<const char*>* files, const char* filter, const char* defaultPath) {
		
		nfdpathset_t pathSet;
		nfdresult_t result = NFD_OpenDialogMultiple (filter, defaultPath, &pathSet);
		
		switch (result) {
			
			case NFD_OKAY:
			{
				printf("okay\n");
				printf("size: %d\n", NFD_PathSet_GetCount (&pathSet));
				for (int i = 0; i < NFD_PathSet_GetCount (&pathSet); i++) {
					
					printf ("%s\n", NFD_PathSet_GetPath (&pathSet, i));
					files->push_back (NFD_PathSet_GetPath (&pathSet, i));
					
				}
				
				//NFD_PathSet_Free (&pathSet);
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
		
		nfdchar_t *savePath = NULL;
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