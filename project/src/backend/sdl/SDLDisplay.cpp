#include <system/Display.h>


namespace lime {
	
	
	int Display::GetNumDevices() {
		
		return SDL_GetNumVideoDisplays();
		
	}
	
	static const char* GetDisplayName (int displayIndex) {
		
		return SDL_GetDisplayName(displayIndex);
		
	}
	
}