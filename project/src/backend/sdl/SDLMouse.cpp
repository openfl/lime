#include "SDLMouse.h"
#include "SDLWindow.h"


namespace lime {
	
	
	MouseCursor Mouse::currentCursor = DEFAULT;
	
	SDL_Cursor* SDLMouse::arrowCursor = 0;
	SDL_Cursor* SDLMouse::crosshairCursor = 0;
	SDL_Cursor* SDLMouse::moveCursor = 0;
	SDL_Cursor* SDLMouse::pointerCursor = 0;
	SDL_Cursor* SDLMouse::resizeNESWCursor = 0;
	SDL_Cursor* SDLMouse::resizeNSCursor = 0;
	SDL_Cursor* SDLMouse::resizeNWSECursor = 0;
	SDL_Cursor* SDLMouse::resizeWECursor = 0;
	SDL_Cursor* SDLMouse::textCursor = 0;
	SDL_Cursor* SDLMouse::waitCursor = 0;
	SDL_Cursor* SDLMouse::waitArrowCursor = 0;
	
	
	void Mouse::Hide () {
		
		SDL_ShowCursor (SDL_DISABLE);
		
	}
	
	
	void Mouse::SetCursor (MouseCursor cursor) {
		
		if (cursor != Mouse::currentCursor) {
			
			switch (cursor) {
				
				case CROSSHAIR:
					
					if (!SDLMouse::crosshairCursor) {
						
						SDLMouse::crosshairCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_CROSSHAIR);
						
					}
					
					SDL_SetCursor (SDLMouse::crosshairCursor);
					break;
				
				case MOVE:
					
					if (!SDLMouse::moveCursor) {
						
						SDLMouse::moveCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_SIZEALL);
						
					}
					
					SDL_SetCursor (SDLMouse::moveCursor);
					break;
				
				case POINTER:
					
					if (!SDLMouse::pointerCursor) {
						
						SDLMouse::pointerCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_HAND);
						
					}
					
					SDL_SetCursor (SDLMouse::pointerCursor);
					break;
				
				case RESIZE_NESW:
					
					if (!SDLMouse::resizeNESWCursor) {
						
						SDLMouse::resizeNESWCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_SIZENESW);
						
					}
					
					SDL_SetCursor (SDLMouse::resizeNESWCursor);
					break;
				
				case RESIZE_NS:
					
					if (!SDLMouse::resizeNSCursor) {
						
						SDLMouse::resizeNSCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_SIZENS);
						
					}
					
					SDL_SetCursor (SDLMouse::resizeNSCursor);
					break;
				
				case RESIZE_NWSE:
					
					if (!SDLMouse::resizeNWSECursor) {
						
						SDLMouse::resizeNWSECursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_SIZENWSE);
						
					}
					
					SDL_SetCursor (SDLMouse::resizeNWSECursor);
					break;
				
				case RESIZE_WE:
					
					if (!SDLMouse::resizeWECursor) {
						
						SDLMouse::resizeWECursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_SIZEWE);
						
					}
					
					SDL_SetCursor (SDLMouse::resizeWECursor);
					break;
				
				case TEXT:
					
					if (!SDLMouse::textCursor) {
						
						SDLMouse::textCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_IBEAM);
						
					}
					
					SDL_SetCursor (SDLMouse::textCursor);
					break;
				
				case WAIT:
					
					if (!SDLMouse::waitCursor) {
						
						SDLMouse::waitCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_WAIT);
						
					}
					
					SDL_SetCursor (SDLMouse::waitCursor);
					break;
				
				case WAIT_ARROW:
					
					if (!SDLMouse::waitArrowCursor) {
						
						SDLMouse::waitArrowCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_WAITARROW);
						
					}
					
					SDL_SetCursor (SDLMouse::waitArrowCursor);
					break;
				
				default:
					
					if (!SDLMouse::arrowCursor) {
						
						SDLMouse::arrowCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_ARROW);
						
					}
					
					SDL_SetCursor (SDLMouse::arrowCursor);
					break;
				
			}
			
			Mouse::currentCursor = cursor;
			
		}
		
	}
	
	
	void Mouse::SetLock (bool lock) {
		
		if (lock) {
			
			SDL_SetRelativeMouseMode (SDL_TRUE);
			
		} else {
			
			SDL_SetRelativeMouseMode (SDL_FALSE);
			
		}
		
	}
  
  void Mouse::SetCaptureMode(bool capture)
  {
    if (capture)
    {
      SDL_CaptureMouse(SDL_TRUE);
    }
    else
    {
      SDL_CaptureMouse(SDL_FALSE);
    }
  }
  
	void Mouse::Show () {
		
		SDL_ShowCursor (SDL_ENABLE);
		
	}
	
	
	void Mouse::Warp (int x, int y, Window* window){
		
		if (window) {
			
			SDL_WarpMouseInWindow (((SDLWindow*)window)->sdlWindow, x, y);
			
		} else {
			
			SDL_WarpMouseGlobal (x, y);
			
		}
		
	}
	
	
}