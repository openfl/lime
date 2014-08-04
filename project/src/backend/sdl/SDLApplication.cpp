#include "SDLApplication.h"

#ifdef HX_MACOS
#include <CoreFoundation/CoreFoundation.h>
#endif


namespace lime {
	
	
	AutoGCRoot* Application::callback = 0;
	
	
	double Application::GetTicks () {
		
		return SDL_GetTicks ();
		
	}
	
	
	SDLApplication::SDLApplication () {
		
		SDL_Init (SDL_INIT_VIDEO | SDL_INIT_TIMER);
		
		currentUpdate = 0;
		lastUpdate = 0;
		nextUpdate = 0;
		
		KeyEvent keyEvent;
		MouseEvent mouseEvent;
		RenderEvent renderEvent;
		TouchEvent touchEvent;
		UpdateEvent updateEvent;
		WindowEvent windowEvent;
		
		#ifdef HX_MACOS
		CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL (CFBundleGetMainBundle ());
		char path[PATH_MAX];
		
		if (CFURLGetFileSystemRepresentation (resourcesURL, TRUE, (UInt8 *)path, PATH_MAX)) {
			
			chdir (path);
			
		}
		
		CFRelease (resourcesURL);
		#endif
		
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
		
		framePeriod = 1000.0 / 60.0;
		SDL_Event event;
		active = true;
		lastUpdate = SDL_GetTicks ();
		nextUpdate = lastUpdate;
		
		bool firstTime = true;
		
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
				
				if (currentUpdate >= nextUpdate) {
					
					SDL_RemoveTimer (timerID);
					OnTimer (0, 0);
					
				} else if (!timerActive) {
					
					timerActive = true;
					timerID = SDL_AddTimer (nextUpdate - currentUpdate, OnTimer, 0);
					
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
				lastUpdate = currentUpdate;
				
				while (nextUpdate <= currentUpdate) {
					
					nextUpdate += framePeriod;
					
				}
				
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
					case SDL_WINDOWEVENT_FOCUS_GAINED:
					case SDL_WINDOWEVENT_FOCUS_LOST:
					case SDL_WINDOWEVENT_MOVED:
						
						ProcessWindowEvent (event);
						break;
					
					case SDL_WINDOWEVENT_EXPOSED: 
						
						RenderEvent::Dispatch (&renderEvent);
						break;
					
					case SDL_WINDOWEVENT_SIZE_CHANGED:
						
						ProcessWindowEvent (event);
						RenderEvent::Dispatch (&renderEvent);
						break;
					
					case SDL_WINDOWEVENT_CLOSE:
						
						ProcessWindowEvent (event);
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
				case SDL_WINDOWEVENT_CLOSE: windowEvent.type = WINDOW_CLOSE; break;
				case SDL_WINDOWEVENT_HIDDEN: windowEvent.type = WINDOW_DEACTIVATE; break;
				case SDL_WINDOWEVENT_FOCUS_GAINED: windowEvent.type = WINDOW_FOCUS_IN; break;
				case SDL_WINDOWEVENT_FOCUS_LOST: windowEvent.type = WINDOW_FOCUS_OUT; break;
				
				case SDL_WINDOWEVENT_MOVED:
					
					windowEvent.type = WINDOW_MOVE;
					windowEvent.x = event->window.data1;
					windowEvent.y = event->window.data2;
					break;
					
				case SDL_WINDOWEVENT_SIZE_CHANGED:
					
					windowEvent.type = WINDOW_RESIZE;
					windowEvent.width = event->window.data1;
					windowEvent.height = event->window.data2;
					break;
				
			}
			
			WindowEvent::Dispatch (&windowEvent);
			
		}
		
	}
	
	
	Application* CreateApplication () {
		
		return new SDLApplication ();
		
	}
	
	
}
