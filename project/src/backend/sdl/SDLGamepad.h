#ifndef LIME_SDL_GAMEPAD_H
#define LIME_SDL_GAMEPAD_H


#include <SDL.h>
#include <ui/Gamepad.h>
#include <map>


namespace lime {


	class SDLGamepad {

		public:

			static bool Connect (int deviceID);
			static int GetInstanceID (int deviceID);
			static bool Disconnect (int id);

	};


}


#endif