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
			virtual void* GetContext ();
			virtual double GetScale ();
			virtual void* Lock (bool useCFFIValue, void* object);
			virtual void MakeCurrent ();
			virtual void ReadPixels (ImageBuffer *buffer, Rectangle *rect);
			virtual const char* Type ();
			virtual void Unlock ();
			
			SDL_Renderer* sdlRenderer;
			SDL_Texture* sdlTexture;
			SDL_Window* sdlWindow;
			
		private:
			
			SDL_GLContext context;
			int width;
			int height;
		
	};
	
	
}


#endif