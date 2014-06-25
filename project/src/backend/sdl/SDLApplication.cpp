#include "SDLApplication.h"


namespace lime {
	
	
	AutoGCRoot* Application::callback = 0;
	
	
	double Application::GetTicks () {
		
		return SDL_GetTicks ();
		
	}
	
	
	SDLApplication::SDLApplication () {
		
		SDL_Init (SDL_INIT_VIDEO | SDL_INIT_TIMER);
		
	}
	
	
	SDLApplication::~SDLApplication () {
		
		
		
	}
	
	
	static SDL_TimerID timerID = 0;
	bool timerActive = false;
	
	
	Uint32 OnTimer (Uint32 interval, void *) {
		
		SDL_Event event;
		SDL_UserEvent userevent;
		userevent.type = SDL_USEREVENT;
		userevent.code = 0;
		userevent.data1 = NULL;
		userevent.data2 = NULL;
		event.type = SDL_USEREVENT;
		event.user = userevent;
		
		timerActive = false;
		timerID = 0;
		
		SDL_PushEvent (&event);
		
		return 0;
		
	}
	
	
	int SDLApplication::Exec () {
		
		SDL_Event event;
		active = true;
		lastUpdate = SDL_GetTicks ();
		
		bool firstTime = true;
		Uint32 nextUpdate = lastUpdate;
		
		while (active) {
			
			event.type = -1;
			
			while (active && (firstTime || SDL_WaitEvent (&event))) {
				
				firstTime = false;
				
				if (timerActive && timerID) {
					
					SDL_RemoveTimer (timerID);
					timerActive = false;
					timerID = 0;
					
				}
				
				HandleEvent (&event);
				event.type = -1;
				if (!active) break;
				
				while (active && SDL_PollEvent (&event)) {
					
					HandleEvent (&event);
					event.type = -1;
					if (!active) break;
					
				}
				
				currentUpdate = SDL_GetTicks ();
				
				if (currentUpdate - lastUpdate < 16) {
					
					timerActive = true;
					timerID = SDL_AddTimer (lastUpdate + 16 - currentUpdate, OnTimer, 0);
					
				} else {
					
					OnTimer (0, 0);
					
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
			
			case SDL_USEREVENT:
				
				currentUpdate = SDL_GetTicks ();
				updateEvent.deltaTime = currentUpdate - lastUpdate;
				UpdateEvent::Dispatch (&updateEvent);
				RenderEvent::Dispatch (&renderEvent);
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
			
			keyEvent.keyCode = event->key.keysym.sym;
			
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
			
			if (event->type != SDL_MOUSEWHEEL) {
				
				mouseEvent.button = event->button.button - 1;
				mouseEvent.x = event->button.x;
				mouseEvent.y = event->button.y;
				
			} else {
				
				mouseEvent.x = event->wheel.x;
				mouseEvent.y = event->wheel.y;
				
			}
			
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