#include <graphics/PixelFormat.h>
#include <math/Rectangle.h>
#include <system/Display.h>
#include <SDL.h>


namespace lime {
	
	
	static int id_bounds;
	static int id_currentMode;
	static int id_height;
	static int id_name;
	static int id_pixelFormat;
	static int id_refreshRate;
	static int id_supportedModes;
	static int id_width;
	static bool init = false;
	
	
	value Display::GetDetails () {
		
		if (!init) {
			
			id_bounds = val_id ("bounds");
			id_currentMode = val_id ("currentMode");
			id_height = val_id ("height");
			id_name = val_id ("name");
			id_pixelFormat = val_id ("pixelFormat");
			id_refreshRate = val_id ("refreshRate");
			id_supportedModes = val_id ("supportedModes");
			id_width = val_id ("width");
			init = true;
			
		}
		
		int numDevices = SDL_GetNumVideoDisplays ();
		value devices = alloc_array (numDevices);
		
		value display, supportedModes, mode;
		int numDisplayModes;
		SDL_Rect bounds = { 0, 0, 0, 0 };
		SDL_DisplayMode currentDisplayMode = { SDL_PIXELFORMAT_UNKNOWN, 0, 0, 0, 0 };
		SDL_DisplayMode displayMode = { SDL_PIXELFORMAT_UNKNOWN, 0, 0, 0, 0 };
		
		for (int i = 0; i < numDevices; i++) {
			
			display = alloc_empty_object ();
			alloc_field (display, id_name, alloc_string (SDL_GetDisplayName (i)));
			SDL_GetDisplayBounds (i, &bounds);
			alloc_field (display, id_bounds, Rectangle (bounds.x, bounds.y, bounds.w, bounds.h).Value ());
			
			SDL_GetCurrentDisplayMode (i, &currentDisplayMode);
			numDisplayModes = SDL_GetNumDisplayModes (i);
			supportedModes = alloc_array (numDisplayModes);
			
			for (int j = 0; j < numDisplayModes; j++) {
				
				SDL_GetDisplayMode (i, j, &displayMode);
				
				if (displayMode.format == currentDisplayMode.format && displayMode.w == currentDisplayMode.w && displayMode.h == currentDisplayMode.h && displayMode.refresh_rate == currentDisplayMode.refresh_rate) {
					
					alloc_field (display, id_currentMode, alloc_int (j));
					
				}
				
				mode = alloc_empty_object ();
				alloc_field (mode, id_height, alloc_int (displayMode.h));
				
				switch (displayMode.format) {
					
					case SDL_PIXELFORMAT_ARGB8888:
						
						alloc_field (mode, id_pixelFormat, alloc_int (ARGB32));
						break;
					
					case SDL_PIXELFORMAT_BGRA8888:
					case SDL_PIXELFORMAT_BGRX8888:
						
						alloc_field (mode, id_pixelFormat, alloc_int (BGRA32));
						break;
					
					default:
						
						alloc_field (mode, id_pixelFormat, alloc_int (RGBA32));
					
				}
				
				alloc_field (mode, id_refreshRate, alloc_int (displayMode.refresh_rate));
				alloc_field (mode, id_width, alloc_int (displayMode.w));
				
				val_array_set_i (supportedModes, j, mode);
				
			}
			
			alloc_field (display, id_supportedModes, supportedModes);
			val_array_set_i (devices, i, display);
			
		}
		
		return devices;
		
	}
	
	
}