#include "SDLGamepad.h"


namespace lime {


	std::map<int, SDL_Gamepad*> gameControllers = std::map<int, SDL_Gamepad*> ();
	std::map<int, int> gameControllerIDs = std::map<int, int> ();


	bool SDLGamepad::Connect (int deviceID) {

		if (SDL_IsGamepad (deviceID)) {

			SDL_Gamepad *gameController = SDL_OpenGamepad (deviceID);

			if (gameController) {

				SDL_Joystick *joystick = SDL_GetGamepadJoystick (gameController);
				int id = SDL_GetJoystickInstanceID (joystick);

				gameControllers[id] = gameController;
				gameControllerIDs[deviceID] = id;

				return true;

			}

		}

		return false;

	}


	bool SDLGamepad::Disconnect (int id) {

		if (gameControllers.find (id) != gameControllers.end ()) {

			SDL_Gamepad *gameController = gameControllers[id];
			SDL_CloseGamepad (gameController);
			gameControllers.erase (id);

			return true;

		}

		return false;

	}


	int SDLGamepad::GetInstanceID (int deviceID) {

		return gameControllerIDs[deviceID];

	}


	void Gamepad::AddMapping (const char* content) {

		SDL_AddGamepadMapping (content);

	}


	const char* Gamepad::GetDeviceGUID (int id) {

		SDL_Joystick* joystick = SDL_GetGamepadJoystick (gameControllers[id]);

		if (joystick) {

			char* guid = new char[64];
			SDL_GetJoystickGUIDString (SDL_GetJoystickGUID (joystick), guid, 64);
			return guid;

		}

		return 0;

	}


	const char* Gamepad::GetDeviceName (int id) {

		return SDL_GetGamepadName (gameControllers[id]);

	}


}