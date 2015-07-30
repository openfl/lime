#ifndef LIME_SYSTEM_DISPLAY_H
#define LIME_SYSTEM_DISPLAY_H

#include <SDL.h>
#include <hx/CFFI.h>

namespace lime {
	
	
	class Display {
		
		public:
			
			value Display::GetCurrentDisplayMode (int displayIndex);
			value Display::GetDisplayMode (int displayIndex, int modeIndex);
			static int GetNumDevices ();
			static const char* GetDisplayName (int displayIndex);
			static int GetNumDisplayModes (int displayIndex);
	
	
}


#endif