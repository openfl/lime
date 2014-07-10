#ifndef LIME_SDL_RENDERER_H
#define LIME_SDL_RENDERER_H


#include <SDL.h>
#include <graphics/Renderer.h>


namespace lime {
	
	
	class SDLRenderer : public Renderer {
		
		public:
			
			SDLRenderer (Window* window);
			~SDLRenderer ();
			
			virtual void Flip ();
			
			SDL_Renderer* sdlRenderer;
			SDL_Window* sdlWindow;
		
	};
	
	
}


#endif