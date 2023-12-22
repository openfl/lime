#ifndef LIME_SDL_GAMEPAD_H
#define LIME_SDL_GAMEPAD_H


#include <SDL.h>
#include <ui/Gamepad.h>
#include <map>


namespace lime {


	class SDLGamepad {
		public:
			SDL_GameController *gameController = nullptr;
			
			SDLGamepad() {}
			SDLGamepad(SDL_GameController *_gameController) : gameController(_gameController) {}
			
			~SDLGamepad() {
				// Close controller if opened
				if (gameController != nullptr)
					SDL_GameControllerClose(gameController);
			}

			void Rumble(int duration, double largeStrength, double smallStrength);

			static bool Connect (int deviceID);
			static int GetInstanceID (int deviceID);
			static bool Disconnect (int id);

			SDLGamepad &operator=(SDLGamepad &&other)
			{
				SDL_GameController *temp = gameController;
				gameController = other.gameController;
				other.gameController = temp;
				return *this;
			}
	};


}


#endif