#include "SDLMouse.h"


namespace lime {
	
	
	MouseCursor Mouse::currentCursor = DEFAULT;
	SDL_Cursor* SDLMouse::defaultCursor = 0;
	SDL_Cursor* SDLMouse::pointerCursor = 0;
	SDL_Cursor* SDLMouse::textCursor = 0;
	
	
	void Mouse::Hide () {
		
		SDL_ShowCursor (SDL_DISABLE);
		
	}
	
	
	void Mouse::SetCursor (MouseCursor cursor) {
		
		if (cursor != Mouse::currentCursor) {
			
			switch (cursor) {
				
				case POINTER:
					
					if (!SDLMouse::pointerCursor) {
						
						SDLMouse::pointerCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_HAND);
						
					}
					
					SDL_SetCursor (SDLMouse::pointerCursor);
					break;
				
				case TEXT:
					
					if (!SDLMouse::textCursor) {
						
						SDLMouse::textCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_IBEAM);
						
					}
					
					SDL_SetCursor (SDLMouse::textCursor);
					break;
				
				default:
					
					if (!SDLMouse::defaultCursor) {
						
						SDLMouse::defaultCursor = SDL_CreateSystemCursor (SDL_SYSTEM_CURSOR_ARROW);
						
					}
					
					SDL_SetCursor (SDLMouse::defaultCursor);
					break;
				
			}
			
			Mouse::currentCursor = cursor;
			
		}
		
		
		
	}
	
	
	void Mouse::Show () {
		
		SDL_ShowCursor (SDL_ENABLE);
		
	}
	
	
}