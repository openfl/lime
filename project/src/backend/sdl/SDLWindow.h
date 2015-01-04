#ifndef LIME_SDL_WINDOW_H
#define LIME_SDL_WINDOW_H


#include <SDL.h>
#include <graphics/ImageBuffer.h>
#include <ui/Window.h>


namespace lime {
	
	
	class SDLWindow : public Window {
		
		public:
			
			SDLWindow (Application* application, int width, int height, int flags, const char* title);
			~SDLWindow ();
			
			virtual void Move (int x, int y);
			virtual void Resize (int width, int height);
			virtual void SetIcon (ImageBuffer *imageBuffer);
			
			SDL_Window* sdlWindow;
		
	};
	
	
}


#endif