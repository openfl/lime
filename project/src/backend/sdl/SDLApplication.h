#ifndef LIME_SDL_APPLICATION_H
#define LIME_SDL_APPLICATION_H


#include <SDL.h>
#include <app/Application.h>
#include <ui/KeyEvent.h>
#include <ui/MouseEvent.h>
#include <ui/TouchEvent.h>


namespace lime {
	
	
	class SDLApplication : public Application {
		
		public:
			
			SDLApplication ();
			~SDLApplication ();
			
			virtual int Exec ();
		
		private:
			
			void HandleEvent (SDL_Event* event);
			void ProcessKeyEvent (SDL_Event* event);
			void ProcessMouseEvent (SDL_Event* event);
			void ProcessTouchEvent (SDL_Event* event);
			
			bool active;
			KeyEvent keyEvent;
			MouseEvent mouseEvent;
			TouchEvent touchEvent;
		
	};
	
	
}


#endif