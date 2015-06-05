#include "SDLApplication.h"
#include "SDLGamepad.h"

#ifdef HX_MACOS
#include <CoreFoundation/CoreFoundation.h>
#endif

#ifdef EMSCRIPTEN
#include "emscripten.h"
#endif


namespace lime {
	
	
	AutoGCRoot* Application::callback = 0;
	SDLApplication* SDLApplication::currentApplication = 0;
	
	
	SDLApplication::SDLApplication () {
		
		if (SDL_Init (SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER | SDL_INIT_TIMER) != 0) {
			
			printf ("Could not initialize SDL: %s.\n", SDL_GetError ());
			
		}
		
		currentApplication = this;
		
		framePeriod = 1000.0 / 60.0;
		
		#ifdef EMSCRIPTEN
		emscripten_cancel_main_loop ();
		emscripten_set_main_loop (UpdateFrame, 0, 0);
		emscripten_set_main_loop_timing (EM_TIMING_RAF, 1);
		#endif
		
		currentUpdate = 0;
		lastUpdate = 0;
		nextUpdate = 0;
		
		GamepadEvent gamepadEvent;
		KeyEvent keyEvent;
		MouseEvent mouseEvent;
		RenderEvent renderEvent;
		TextEvent textEvent;
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
	
	
	int SDLApplication::Exec () {
		
		Init ();
		
		#ifdef EMSCRIPTEN
		
		return 0;
		
		#else
		
		while (active) {
			
			Update ();
			
		}
		
		return Quit ();
		
		#endif
		
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
			
			case SDL_APP_WILLENTERBACKGROUND:
				
				windowEvent.type = WINDOW_DEACTIVATE;
				WindowEvent::Dispatch (&windowEvent);
				break;
			
			case SDL_APP_WILLENTERFOREGROUND:
				
				windowEvent.type = WINDOW_ACTIVATE;
				WindowEvent::Dispatch (&windowEvent);
				break;
			
			case SDL_CONTROLLERAXISMOTION:
			case SDL_CONTROLLERBUTTONDOWN:
			case SDL_CONTROLLERBUTTONUP:
			case SDL_CONTROLLERDEVICEADDED:
			case SDL_CONTROLLERDEVICEREMOVED:
				
				ProcessGamepadEvent (event);
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
			
			case SDL_TEXTINPUT:
			case SDL_TEXTEDITING:
				
				ProcessTextEvent (event);
				break;
			
			case SDL_WINDOWEVENT:
				
				switch (event->window.event) {
					
					case SDL_WINDOWEVENT_ENTER:
					case SDL_WINDOWEVENT_LEAVE:
					case SDL_WINDOWEVENT_SHOWN:
					case SDL_WINDOWEVENT_HIDDEN:
					case SDL_WINDOWEVENT_FOCUS_GAINED:
					case SDL_WINDOWEVENT_FOCUS_LOST:
					case SDL_WINDOWEVENT_MINIMIZED:
					case SDL_WINDOWEVENT_MOVED:
					case SDL_WINDOWEVENT_RESTORED:
						
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
	
	
	void SDLApplication::Init () {
		
		active = true;
		lastUpdate = SDL_GetTicks ();
		nextUpdate = lastUpdate;
		
	}
	
	
	void SDLApplication::ProcessGamepadEvent (SDL_Event* event) {
		
		if (GamepadEvent::callback) {
			
			switch (event->type) {
				
				case SDL_CONTROLLERAXISMOTION:
					
					gamepadEvent.type = AXIS_MOVE;
					gamepadEvent.axis = event->caxis.axis;
					gamepadEvent.id = event->caxis.which;
					gamepadEvent.axisValue = event->caxis.value / 32768.0;
					
					GamepadEvent::Dispatch (&gamepadEvent);
					break;
				
				case SDL_CONTROLLERBUTTONDOWN:
					
					gamepadEvent.type = BUTTON_DOWN;
					gamepadEvent.button = event->cbutton.button;
					gamepadEvent.id = event->cbutton.which;
					
					GamepadEvent::Dispatch (&gamepadEvent);
					break;
				
				case SDL_CONTROLLERBUTTONUP:
					
					gamepadEvent.type = BUTTON_UP;
					gamepadEvent.button = event->cbutton.button;
					gamepadEvent.id = event->cbutton.which;
					
					GamepadEvent::Dispatch (&gamepadEvent);
					break;
				
				case SDL_CONTROLLERDEVICEADDED:
					
					if (SDLGamepad::Connect (event->cdevice.which)) {
						
						gamepadEvent.type = CONNECT;
						gamepadEvent.id = SDLGamepad::GetInstanceID (event->cdevice.which);
						
						GamepadEvent::Dispatch (&gamepadEvent);
						
					}
					
					break;
				
				case SDL_CONTROLLERDEVICEREMOVED: {
					
					gamepadEvent.type = DISCONNECT;
					gamepadEvent.id = event->cdevice.which;
					
					GamepadEvent::Dispatch (&gamepadEvent);
					SDLGamepad::Disconnect (event->cdevice.which);
					break;
					
				}
				
			}
			
		}
		
	}
	
	
	void SDLApplication::ProcessKeyEvent (SDL_Event* event) {
		
		if (KeyEvent::callback) {
			
			switch (event->type) {
				
				case SDL_KEYDOWN: keyEvent.type = KEY_DOWN; break;
				case SDL_KEYUP: keyEvent.type = KEY_UP; break;
				
			}
			
			keyEvent.keyCode = event->key.keysym.sym;
			keyEvent.modifier = event->key.keysym.mod;
			
			KeyEvent::Dispatch (&keyEvent);
			
		}
		
	}
	
	
	void SDLApplication::ProcessMouseEvent (SDL_Event* event) {
		
		if (MouseEvent::callback) {
			
			switch (event->type) {
				
				case SDL_MOUSEMOTION:
					
					mouseEvent.type = MOUSE_MOVE;
					mouseEvent.x = event->motion.x;
					mouseEvent.y = event->motion.y;
					mouseEvent.movementX = event->motion.xrel;
					mouseEvent.movementY = event->motion.yrel;
					break;
				
				case SDL_MOUSEBUTTONDOWN:
					
					mouseEvent.type = MOUSE_DOWN;
					mouseEvent.button = event->button.button - 1;
					mouseEvent.x = event->button.x;
					mouseEvent.y = event->button.y;
					break;
				
				case SDL_MOUSEBUTTONUP:
					
					mouseEvent.type = MOUSE_UP;
					mouseEvent.button = event->button.button - 1;
					mouseEvent.x = event->button.x;
					mouseEvent.y = event->button.y;
					break;
				
				case SDL_MOUSEWHEEL:
					
					mouseEvent.type = MOUSE_WHEEL;
					mouseEvent.x = event->wheel.x;
					mouseEvent.y = event->wheel.y;
					break;
				
			}
			
			MouseEvent::Dispatch (&mouseEvent);
			
		}
		
	}
	
	
	void SDLApplication::ProcessTextEvent (SDL_Event* event) {
		
		if (TextEvent::callback) {
			
			switch (event->type) {
				
				case SDL_TEXTINPUT:
					
					textEvent.type = TEXT_INPUT;
					break;
				
				case SDL_TEXTEDITING:
					
					textEvent.type = TEXT_EDIT;
					textEvent.start = event->edit.start;
					textEvent.length = event->edit.length;
					break;
				
			}
			
			strcpy (textEvent.text, event->text.text);
			
			TextEvent::Dispatch (&textEvent);
			
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
				case SDL_WINDOWEVENT_ENTER: windowEvent.type = WINDOW_ENTER; break;
				case SDL_WINDOWEVENT_FOCUS_GAINED: windowEvent.type = WINDOW_FOCUS_IN; break;
				case SDL_WINDOWEVENT_FOCUS_LOST: windowEvent.type = WINDOW_FOCUS_OUT; break;
				case SDL_WINDOWEVENT_LEAVE: windowEvent.type = WINDOW_LEAVE; break;
				case SDL_WINDOWEVENT_MINIMIZED: windowEvent.type = WINDOW_MINIMIZE; break;
				
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
				
				case SDL_WINDOWEVENT_RESTORED: windowEvent.type = WINDOW_RESTORE; break;
				
			}
			
			WindowEvent::Dispatch (&windowEvent);
			
		}
		
	}
	
	
	int SDLApplication::Quit () {
		
		windowEvent.type = WINDOW_DEACTIVATE;
		WindowEvent::Dispatch (&windowEvent);
		
		SDL_Quit ();
		
		return 0;
		
	}
	
	
	void SDLApplication::RegisterWindow (SDLWindow *window) {
		
		#ifdef IPHONE
		SDL_iPhoneSetAnimationCallback (window->sdlWindow, 1, UpdateFrame, NULL);
		#endif
		
	}
	
	
	void SDLApplication::SetFrameRate (double frameRate) {
		
		if (frameRate > 0) {
			
			framePeriod = 1000.0 / frameRate;
			
		} else {
			
			framePeriod = 1000.0;
			
		}
		
	}
	
	
	static SDL_TimerID timerID = 0;
	bool timerActive = false;
	bool firstTime = true;
	
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
	
	
	bool SDLApplication::Update () {
		
		SDL_Event event;
		event.type = -1;
		
		#if (!defined (IPHONE) && !defined (EMSCRIPTEN))
		
		if (active && (firstTime || SDL_WaitEvent (&event))) {
			
			firstTime = false;
			
			HandleEvent (&event);
			event.type = -1;
			if (!active)
				return active;
			
		#endif
			
			while (SDL_PollEvent (&event)) {
				
				HandleEvent (&event);
				event.type = -1;
				if (!active)
					return active;
				
			}
			
			currentUpdate = SDL_GetTicks ();
			
		#if defined (IPHONE)
			
			if (currentUpdate >= nextUpdate) {
				
				event.type = SDL_USEREVENT;
				HandleEvent (&event);
				event.type = -1;
				
			}
		
		#elif defined (EMSCRIPTEN)
			
			event.type = SDL_USEREVENT;
			HandleEvent (&event);
			event.type = -1;
		
		#else
			
			if (currentUpdate >= nextUpdate) {
				
				SDL_RemoveTimer (timerID);
				OnTimer (0, 0);
				
			} else if (!timerActive) {
				
				timerActive = true;
				timerID = SDL_AddTimer (nextUpdate - currentUpdate, OnTimer, 0);
				
			}
			
		}
		
		#endif
		
		return active;
		
	}
	
	
	void SDLApplication::UpdateFrame () {
		
		currentApplication->Update ();
		
	}
	
	
	void SDLApplication::UpdateFrame (void*) {
		
		UpdateFrame ();
		
	}
	
	
	Application* CreateApplication () {
		
		return new SDLApplication ();
		
	}
	
	
}


#ifdef ANDROID
int SDL_main (int argc, char *argv[]) { return 0; }
#endif