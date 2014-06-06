#ifndef LIME_SDL_APPLICATION_H
#define LIME_SDL_APPLICATION_H


#include <SDL.h>
#include "Application.h"


namespace lime {
	
	
	class SDLApplication : public Application {
		
		public:
			
			SDLApplication ();
			~SDLApplication ();
			
			virtual int Exec ();
		
	};
	
	
}


#endif