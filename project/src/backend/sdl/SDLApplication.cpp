#include "SDLApplication.h"


namespace lime {
	
	
	SDLApplication::SDLApplication () {
		
		SDL_Init (SDL_INIT_VIDEO);
		
	}
	
	
	SDLApplication::~SDLApplication () {
		
		
		
	}
	
	
	int SDLApplication::Exec () {
		
		SDL_Event event;
		active = true;
		
		while (active) {
			
			while (active && SDL_WaitEvent (&event)) {
				
				HandleEvent (&event);
				event.type = -1;
				if (!active) break;
				
			}
			
			while (active && SDL_PollEvent (&event)) {
				
				HandleEvent (&event);
				event.type = -1;
				if (!active) break;
				
			}
			
		}
		
		SDL_Quit ();
		
		return 0;
		
	}
	
	
	void SDLApplication::HandleEvent (SDL_Event* event) {
		
		switch (event->type) {
			
			case SDL_QUIT:
				
				//quit
				active = false;
				break;
			
			case SDL_WINDOWEVENT:
				
				switch (event->window.event) {
					
					case SDL_WINDOWEVENT_SHOWN:
						
						//activate
						break;
					
					case SDL_WINDOWEVENT_HIDDEN:
						
						//deactivate
						break;
					
					case SDL_WINDOWEVENT_EXPOSED:
						
						//poll
						break;
					
					case SDL_WINDOWEVENT_SIZE_CHANGED:
						
						//resize
						break;
					
					case SDL_WINDOWEVENT_FOCUS_GAINED:
						
						//focus in
						break;
					
					case SDL_WINDOWEVENT_FOCUS_LOST:
						
						//focus out
						break;
					
					case SDL_WINDOWEVENT_CLOSE:
						
						active = false;
						break;
					
					default:
						
						break;
					
				}
			
			case SDL_MOUSEMOTION:
			case SDL_MOUSEBUTTONDOWN:
			case SDL_MOUSEBUTTONUP:
			case SDL_MOUSEWHEEL:
				
				ProcessMouseEvent (event);
				break;
			
			case SDL_KEYDOWN:
			case SDL_KEYUP:
				
				ProcessKeyEvent (event);
				break;
			
			case SDL_JOYAXISMOTION:
			case SDL_JOYBALLMOTION:
			case SDL_JOYBUTTONDOWN:
			case SDL_JOYBUTTONUP:
			case SDL_JOYHATMOTION:
			case SDL_JOYDEVICEADDED:
			case SDL_JOYDEVICEREMOVED:
				
				//joy
				break;
			
		}
		
	}
	
	
	void SDLApplication::ProcessKeyEvent (SDL_Event* event) {
		
		if (KeyEvent::callback) {
			
			switch (event->type) {
				
				case SDL_KEYDOWN: keyEvent.type = KEY_DOWN; break;
				case SDL_KEYUP: keyEvent.type = KEY_UP; break;
				
			}
			
			keyEvent.code = event->key.keysym.sym;
			
			KeyEvent::Dispatch (&keyEvent);
			
		}
		
	}
	
	
	void SDLApplication::ProcessMouseEvent (SDL_Event* event) {
		
		if (MouseEvent::callback) {
			
			switch (event->type) {
				
				case SDL_MOUSEMOTION: mouseEvent.type = MOUSE_MOVE; break;
				case SDL_MOUSEBUTTONDOWN: mouseEvent.type = MOUSE_DOWN; break;
				case SDL_MOUSEBUTTONUP: mouseEvent.type = MOUSE_UP; break;
				case SDL_MOUSEWHEEL: mouseEvent.type = MOUSE_WHEEL; break;
				
			}
			
			mouseEvent.id = event->button.button - 1;
			mouseEvent.x = event->button.x;
			mouseEvent.y = event->button.y;
			
			MouseEvent::Dispatch (&mouseEvent);
			
		}
		
	}
	
	
	void SDLApplication::ProcessTouchEvent (SDL_Event* event) {
		
		
		
	}
	
	
	Application* CreateApplication () {
		
		return new SDLApplication ();
		
	}
	
	
}