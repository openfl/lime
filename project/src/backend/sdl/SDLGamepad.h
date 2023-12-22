#ifndef LIME_SDL_GAMEPAD_H
#define LIME_SDL_GAMEPAD_H


#include <SDL.h>
#include <ui/Gamepad.h>
#include <map>


namespace lime {


	class SDLGamepad {
		public:
			SDL_GameController *gameController = nullptr;
			SDL_Joystick *joystick = nullptr;
			
			SDLGamepad() {}
			SDLGamepad(SDL_GameController *_gameController);
			~SDLGamepad();

			void Rumble(int duration, double largeStrength, double smallStrength);

			static bool Connect (int deviceID);
			static int GetInstanceID (int deviceID);
			static bool Disconnect (int id);

	};


}


#endif