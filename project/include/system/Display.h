#ifndef LIME_SYSTEM_DISPLAY_H
#define LIME_SYSTEM_DISPLAY_H

#include <SDL.h>
#include <hx/CFFI.h>

namespace lime {
	
	
	class Display {
		
		public:
			
			static value GetCurrentDisplayMode (int displayIndex);
			static value GetDisplayMode (int displayIndex, int modeIndex);
			static value GetDisplayBounds (int displayIndex);
			static int GetNumDevices ();
			static const char* GetDisplayName (int displayIndex);
			static int GetNumDisplayModes (int displayIndex);
	
	};
}


#endif