#include <system/Display.h>


namespace lime {
	
	
	int Display::GetNumDevices() {
		
		return SDL_GetNumVideoDisplays();
		
	}
	
	const char* Display::GetDisplayName (int displayIndex) {
		
		return SDL_GetDisplayName(displayIndex);
		
	}
	
}