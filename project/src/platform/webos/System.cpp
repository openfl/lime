#include "PDL.h"
#include <Utils.h>
#include <syslog.h>
#include <string>


namespace lime {
	
	
	AutoGCRoot *sExternalInterfaceHandler = 0;
	
	
	std::string CapabilitiesGetLanguage () {
		
		char locale[5];
		PDL_GetLanguage(locale, sizeof(locale));
		return locale;
		
	}
	
	double CapabilitiesGetScreenDPI() {
		PDL_ScreenMetrics screenMetrics;
		PDL_GetScreenMetrics (&screenMetrics);

		return (screenMetrics.horizontalDPI + screenMetrics.verticalDPI) * 0.5;
	}
	
	double CapabilitiesGetPixelAspectRatio() {
		PDL_ScreenMetrics screenMetrics;
		PDL_GetScreenMetrics (&screenMetrics);

		return screenMetrics.aspectRatio;
	}
	
	bool LaunchBrowser (const char *inUtf8URL) {
		
		PDL_LaunchBrowser (inUtf8URL);		
		return true;		
		
	}
	
	
	PDL_bool ExternalInterface_CallbackHandler (PDL_JSParameters *params) {
		
		const char *methodName = PDL_GetJSFunctionName (params);
		int numParams = PDL_GetNumJSParams (params);
		value paramValues = alloc_array (numParams);
		
		for (int i = 0; i++; i < numParams) {
			
			val_array_set_i (paramValues, i, alloc_string (PDL_GetJSParamString (params, i)));
			
		}
		
		const char *returnValue = val_string (val_call2 (sExternalInterfaceHandler->get(), alloc_string (methodName), paramValues));
		
		if (returnValue != NULL) {
			
			PDL_JSReply (params, returnValue);
			
		}
		
	}
	
	
	void ExternalInterface_AddCallback (const char *functionName, AutoGCRoot *inCallback) {
		
		if (sExternalInterfaceHandler == 0) {
			
			sExternalInterfaceHandler = inCallback;
			
		}
		
		PDL_RegisterJSHandler (functionName, ExternalInterface_CallbackHandler);
		
	}
	
	
	void ExternalInterface_Call (const char *functionName, const char **params, int numParams) {
		
		PDL_CallJS (functionName, params, numParams);
		
	}
	
	
	void ExternalInterface_RegisterCallbacks () {
		
		PDL_JSRegistrationComplete();
		
	}
	
	
	void HapticVibrate (int period, int duration) {
		
		if (PDL_GetPDKVersion () >= 200) {
			
			PDL_Vibrate (period, duration);
			
		}
		
	}
	
	
	std::string GetUserPreference(const char *inId) {
		
		return "";
		
	}
	
	
	bool SetUserPreference(const char *inId, const char *inPreference) {
		
		return false;
		
	}
	
	
	bool ClearUserPreference(const char *inId) {
		
		return false;
		
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

