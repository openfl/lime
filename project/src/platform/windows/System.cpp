#include <windows.h>
#include <shlobj.h> 

#include <stdio.h>
#include <string>
#include <vector>

namespace lime {
	
	bool LaunchBrowser(const char *inUtf8URL)
	{
		int result;
		result=(int)ShellExecute(NULL, "open", inUtf8URL, NULL, NULL, SW_SHOWDEFAULT);
		return (result>32);
	}

	std::string CapabilitiesGetLanguage()
	{
		char locale[8];
		int lang_len = GetLocaleInfo(GetSystemDefaultUILanguage(), LOCALE_SISO639LANGNAME, locale, sizeof(locale));
		return std::string(locale, lang_len);
	}
	
	bool SetDPIAware()
	{
		HMODULE usr32 = LoadLibrary("user32.dll");
		if(!usr32) return false;
		
		BOOL (*addr)() = (BOOL (*)())GetProcAddress(usr32, "SetProcessDPIAware");
		return addr ? addr() : false;
	}

	bool dpiAware = SetDPIAware();

	double CapabilitiesGetScreenDPI()
	{
		HDC screen = GetDC(NULL);
		/* It reports 72... :(
		double hSize = GetDeviceCaps(screen, HORZSIZE);
		double vSize = GetDeviceCaps(screen, VERTSIZE);
		double hRes = GetDeviceCaps(screen, HORZRES);
		double vRes = GetDeviceCaps(screen, VERTRES);
		double hPixelsPerInch = hRes / hSize * 25.4;
		double vPixelsPerInch = vRes / vSize * 25.4;
		*/
		double hPixelsPerInch = GetDeviceCaps(screen,LOGPIXELSX);
		double vPixelsPerInch = GetDeviceCaps(screen,LOGPIXELSY);
		ReleaseDC(NULL, screen);
		return (hPixelsPerInch + vPixelsPerInch) * 0.5;
	}

	double CapabilitiesGetPixelAspectRatio() {
		HDC screen = GetDC(NULL);
		double hPixelsPerInch = GetDeviceCaps(screen,LOGPIXELSX);
		double vPixelsPerInch = GetDeviceCaps(screen,LOGPIXELSY);
		ReleaseDC(NULL, screen);
		return hPixelsPerInch / vPixelsPerInch;
	}


	std::string FileDialogFolder( const std::string &title, const std::string &text ) {

		char path[MAX_PATH];
	    BROWSEINFO bi = { 0 };
	    bi.lpszTitle = ("All Folders Automatically Recursed.");
	    LPITEMIDLIST pidl = SHBrowseForFolder ( &bi );

	    if ( pidl != 0 ) {
	        // get the name of the folder and put it in path
	        SHGetPathFromIDList ( pidl, path );


	        // free memory used
	        IMalloc * imalloc = 0;
	        if ( SUCCEEDED( SHGetMalloc ( &imalloc )) )
	        {
	            imalloc->Free ( pidl );
	            imalloc->Release ( );
	        }

	        return std::string(path);
	    }
		
		return ""; 
	}

	std::string FileDialogOpen( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { 

		OPENFILENAME ofn;
	    char path[MAX_PATH] = "";

	    ZeroMemory(&ofn, sizeof(ofn));

	    ofn.lStructSize = sizeof(ofn);
	    ofn.lpstrFilter = "All Files (*.*)\0*.*\0";
	    ofn.lpstrFile = path;
	    ofn.lpstrTitle = title.c_str();
	    ofn.nMaxFile = MAX_PATH;
	    ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_ALLOWMULTISELECT;
	    ofn.lpstrDefExt = "*";

	    if(GetOpenFileName(&ofn)) {
			return std::string( ofn.lpstrFile ); 
	    } 

		return ""; 
	}

	std::string FileDialogSave( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { 

		OPENFILENAME ofn;
	    char path[1024] = "";

	    ZeroMemory(&ofn, sizeof(ofn));

	    ofn.lStructSize = sizeof(ofn);
	    ofn.lpstrFilter = "All Files (*.*)\0*.*\0";
	    ofn.lpstrFile = path;
	    ofn.lpstrTitle = title.c_str();
	    ofn.nMaxFile = MAX_PATH;
	    ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_ALLOWMULTISELECT;
	    ofn.lpstrDefExt = "*";

	    if(GetSaveFileName(&ofn))  {
			return std::string( ofn.lpstrFile ); 
	    }

		return ""; 
	}

}
