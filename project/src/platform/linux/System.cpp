#include <Utils.h>
#include <string>
#include <stdlib.h>
#include <clocale>
#include <X11/Xlib.h>


using namespace std;


namespace lime {
	
	
	std::string CapabilitiesGetLanguage () {
		
		const char* locale = getenv ("LANG");
		
		if (locale == NULL) {
			
			locale = setlocale (LC_ALL, "");
			
		}
		
		if (locale != NULL) {
			
			return std::string (locale);
			
		}
		
		return NULL;
		
	}
	
	
	bool LaunchBrowser (const char *inUtf8URL) {
		
		string url = inUtf8URL;
		string command = "xdg-open " + url;
		
		int result = system(command.c_str());
		
		return (result != -1);
		
	}
	
	#ifdef SDL_OGL
	double CapabilitiesGetScreenDPI() {
		double xres, yres;
		Display *dpy;
		char *displayname = NULL;
		int scr = 0; /* Screen number */

		dpy = XOpenDisplay (displayname);
		
		xres = ((((double) DisplayWidth(dpy,scr)) * 25.4) / 
				((double) DisplayWidthMM(dpy,scr)));
		yres = ((((double) DisplayHeight(dpy,scr)) * 25.4) / 
				((double) DisplayHeightMM(dpy,scr)));

		XCloseDisplay (dpy);
		
		return (xres + yres) * 0.5;
	}

	double CapabilitiesGetPixelAspectRatio() {
		double xres, yres;
		Display *dpy;
		char *displayname = NULL;
		int scr = 0; /* Screen number */

		dpy = XOpenDisplay (displayname);
		
		xres = ((((double) DisplayWidth(dpy,scr)) * 25.4) / 
				((double) DisplayWidthMM(dpy,scr)));
		yres = ((((double) DisplayHeight(dpy,scr)) * 25.4) / 
				((double) DisplayHeightMM(dpy,scr)));

		XCloseDisplay (dpy);
		
		return xres / yres;
	}
	#else
	double CapabilitiesGetScreenDPI() {
		return 72;
	}

	double CapabilitiesGetPixelAspectRatio() {
		return 1;
	}
	#endif

//File dialogs
	std::string FileDialogFolder( const std::string &title, const std::string &text ) {
		return ""; 
	}

	std::string FileDialogOpen( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { 
		return ""; 
	}

	std::string FileDialogSave( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { 
		return ""; 
	}
}
