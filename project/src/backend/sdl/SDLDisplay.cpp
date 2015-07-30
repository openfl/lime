#include <system/Display.h>


namespace lime {
	
	
	int SDLDisplay::GetNumDevices() {
		
		return SDL_GetNumVideoDisplays();
		
	}
	
	
}