#include "SDLApplication.h"


namespace lime {
	
	
	AutoGCRoot* Application::callback = 0;
	
	
	double Application::GetTicks () {
		
		return SDL_GetTicks ();
		
	}
	
	
	SDLApplication::SDLApplication () {
		
		SDL_Init (SDL_INIT_VIDEO);
		
	}
	
	
	SDLApplication::~SDLApplication () {
		
		
		
	}
	
	
	int SDLApplication::Exec () {
		
		SDL_Event event;
		active = true;
		bool firstTime = true;
		lastUpdate = SDL_GetTicks ();
		Uint32 currentUpdate = 0;
		int deltaTime = 0;
		
		while (active) {
			
			event.type = -1;
			
			while (active && (firstTime || SDL_WaitEvent (&event))) {
				
				firstTime = false;
				
				HandleEvent (&event);
				event.type = -1;
				if (!active) break;
				
				while (active && SDL_PollEvent (&event)) {
					
					HandleEvent (&event);
					event.type = -1;
					if (!active) break;
					
				}
				
				currentUpdate = SDL_GetTicks ();
				deltaTime = currentUpdate - lastUpdate;
				
				if (deltaTime > 16) {
					
					updateEvent.deltaTime = deltaTime;
					UpdateEvent::Dispatch (&updateEvent);
					
					RenderEvent::Dispatch (&renderEvent);
					
				}
				
			}
			
		}
		
		windowEvent.type = WINDOW_DEACTIVATE;
		WindowEvent::Dispatch (&windowEvent);
		
		SDL_Quit ();
		
		return 0;
		
	}
	
	
	void SDLApplication::HandleEvent (SDL_Event* event) {
		
		switch (event->type) {
			
			case SDL_JOYAXISMOTION:
			case SDL_JOYBALLMOTION:
			case SDL_JOYBUTTONDOWN:
			case SDL_JOYBUTTONUP:
			case SDL_JOYHATMOTION:
			case SDL_JOYDEVICEADDED:
			case SDL_JOYDEVICEREMOVED:
				
				//joy
				break;
			
			case SDL_KEYDOWN:
			case SDL_KEYUP:
				
				ProcessKeyEvent (event);
				break;
			
			case SDL_MOUSEMOTION:
			case SDL_MOUSEBUTTONDOWN:
			case SDL_MOUSEBUTTONUP:
			case SDL_MOUSEWHEEL:
				
				ProcessMouseEvent (event);
				break;
			
			case SDL_WINDOWEVENT:
				
				switch (event->window.event) {
					
					case SDL_WINDOWEVENT_SHOWN:
					case SDL_WINDOWEVENT_HIDDEN:
						
						ProcessWindowEvent (event);
						break;
					
					case SDL_WINDOWEVENT_EXPOSED: 
						
						RenderEvent::Dispatch (&renderEvent);
						break;
					
					case SDL_WINDOWEVENT_SIZE_CHANGED: /*resize*/ break;
					case SDL_WINDOWEVENT_FOCUS_GAINED: /*focus in*/ break;
					case SDL_WINDOWEVENT_FOCUS_LOST: /*focus out*/ break;
					case SDL_WINDOWEVENT_CLOSE:
						
						active = false;
						break;
					
				}
				
				break;
			
			case SDL_QUIT:
				
				//quit
				active = false;
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
	
	
	void SDLApplication::ProcessWindowEvent (SDL_Event* event) {
		
		if (WindowEvent::callback) {
			
			switch (event->window.event) {
				
				case SDL_WINDOWEVENT_SHOWN: windowEvent.type = WINDOW_ACTIVATE; break;
				case SDL_WINDOWEVENT_HIDDEN: windowEvent.type = WINDOW_DEACTIVATE; break;
				
			}
			
			WindowEvent::Dispatch (&windowEvent);
			
		}
		
	}
	
	
	Application* CreateApplication () {
		
		return new SDLApplication ();
		
	}
	
	
}