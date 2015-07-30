#ifndef LIME_SYSTEM_DISPLAY_H
#define LIME_SYSTEM_DISPLAY_H

#include <SDL.h>

namespace lime {
	
	
	class Display {
		
		public:
			
			static int GetNumDevices ();
			static const char* GetDisplayName (int displayIndex);
		
	};
	
	
}


#endif