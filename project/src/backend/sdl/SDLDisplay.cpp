#include <system/Display.h>


namespace lime {
	
	
	int Display::GetNumDevices() {
		
		return SDL_GetNumVideoDisplays();
		
	}
	
	
}