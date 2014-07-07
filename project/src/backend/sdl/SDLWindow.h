#ifndef LIME_SDL_WINDOW_H
#define LIME_SDL_WINDOW_H


#include <SDL.h>
#include <ui/Window.h>


namespace lime {
	
	enum SDLWindowFlags
	{
		DEPTH_BUFFER    = 0x00000200,
		STENCIL_BUFFER  = 0x00000400,
	};
	
	class SDLWindow : public Window {
		
		public:
			
			SDLWindow (Application* application, int width, int height, int flags);
			~SDLWindow ();
			
			SDL_Window* sdlWindow;
		
	};
	
	
}


#endif