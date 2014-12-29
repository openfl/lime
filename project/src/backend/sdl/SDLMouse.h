#ifndef LIME_SDL_MOUSE_H
#define LIME_SDL_MOUSE_H


#include <SDL.h>
#include <ui/Mouse.h>
#include <ui/MouseCursor.h>


namespace lime {
	
	
	class SDLMouse {
		
		public:
			
			static SDL_Cursor* defaultCursor;
			static SDL_Cursor* pointerCursor;
			static SDL_Cursor* textCursor;
		
	};
	
	
}


#endif