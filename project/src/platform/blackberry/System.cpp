#include <math.h>
#include <stdbool.h>
#include <stdlib.h>
#include <bps/accelerometer.h>
#include <bps/locale.h>
#include <bps/navigator.h>
#include <sys/platform.h>
#include "bps/event.h"
#include <string>
#include <vector>
#include <stdio.h>

#include <bps/orientation.h>
#include <bps/bps.h>

namespace lime {
	
	
	std::string CapabilitiesGetLanguage () {
		
		char* country = NULL;
		char* language = NULL;
		
		locale_get(&language, &country);
		
		return std::string(language) + "-" + std::string(country);
		
	}
	
	
	double CapabilitiesGetScreenResolutionX() {
		
		return 1024;
		
	}
	

	double CapabilitiesGetScreenResolutionY() {
		
		return 600;
		
	}
	

	double CapabilitiesGetScreenDPI() {
		
		return 170;
		
	}
	

	double CapabilitiesGetPixelAspectRatio() {
		
		return 1;
		
	}

	
	bool GetAcceleration (double &outX, double &outY, double &outZ) {
		
		int result = accelerometer_read_forces (&outX, &outY, &outZ);
		
		if (getenv ("FORCE_PORTRAIT") != NULL) {
			
			int cache = outX;
			outX = outY;
			outY = -cache;
			
		}
		
		outZ = -outZ;
		
		return (result == BPS_SUCCESS);
		//return (accelerometer_read_forces (&outX, &outY, &outZ) == BPS_SUCCESS);
		
	}
	
	
	void HapticVibrate (int period, int duration) {
		
		
		
	}
	
	
	bool LaunchBrowser (const char *inUtf8URL) {
		
		char* err;
		
		int result = navigator_invoke (inUtf8URL, &err);
		
		bps_free (err);
		
		return (result == BPS_SUCCESS);
		
	}

    int GetDeviceOrientation() {
        int orientation_angle = 0;
        orientation_direction_t direction;
        orientation_get(&direction, &orientation_angle);
        switch (direction) {
            case ORIENTATION_TOP_UP:        return 1; break;
            case ORIENTATION_BOTTOM_UP:     return 2; break;
            case ORIENTATION_LEFT_UP:       return 3; break;
            case ORIENTATION_RIGHT_UP:      return 4; break;
                
            default:
                return 0;
        }
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
