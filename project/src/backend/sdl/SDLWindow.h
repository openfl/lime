#ifndef LIME_SDL_WINDOW_H
#define LIME_SDL_WINDOW_H


#include <SDL.h>
#include "Window.h"


namespace lime {
	
	
	class SDLWindow : public Window {
		
		public:
			
			SDLWindow (Application* application);
			~SDLWindow ();
			
			SDL_Window* sdlWindow;
		
	};
	
	
}


#endif