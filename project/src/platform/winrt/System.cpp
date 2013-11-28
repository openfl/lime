#include <windows.h>
#include <stdio.h>
#include <string>

namespace lime
{

bool LaunchBrowser(const char *inUtf8URL)
{
   return false;
}

std::string CapabilitiesGetLanguage()
{
   return "";
}

//bool dpiAware = SetProcessDPIAware();

double CapabilitiesGetScreenDPI()
{
   return 96;
}

double CapabilitiesGetPixelAspectRatio()
{
   return 1.0;
}

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
