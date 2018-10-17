#ifndef LIME_SDL_CURSOR_H
#define LIME_SDL_CURSOR_H


#include <SDL.h>


namespace lime {


	class SDLCursor {

		public:

			static SDL_Cursor* arrowCursor;
			static SDL_Cursor* crosshairCursor;
			static SDL_Cursor* moveCursor;
			static SDL_Cursor* pointerCursor;
			static SDL_Cursor* resizeNESWCursor;
			static SDL_Cursor* resizeNSCursor;
			static SDL_Cursor* resizeNWSECursor;
			static SDL_Cursor* resizeWECursor;
			static SDL_Cursor* textCursor;
			static SDL_Cursor* waitCursor;
			static SDL_Cursor* waitArrowCursor;

	};


}


#endif