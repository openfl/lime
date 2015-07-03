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
			virtual value Lock ();
			virtual void Unlock ();
			
			SDL_Renderer* sdlRenderer;
			SDL_Texture* sdlTexture;
			SDL_Window* sdlWindow;
			
		private:
			
			int width;
			int height;
		
	};
	
	
}


#endif