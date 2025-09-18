#include "SDLGamepad.h"


namespace lime {


	std::map<int, SDL_Gamepad*> gameControllers = std::map<int, SDL_Gamepad*> ();
	std::map<int, int> gameControllerIDs = std::map<int, int> ();


	bool SDLGamepad::Connect (int deviceID) {

		if (SDL_IsGamepad (deviceID)) {

			SDL_Gamepad *gameController = SDL_OpenGamepad (deviceID);

			if (gameController) {

				SDL_Joystick *joystick = SDL_GetGamepadJoystick (gameController);
				int id = SDL_GetJoystickID (joystick);

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
			SDL_GUIDToString (SDL_GetJoystickGUID (joystick), guid, 64);
			return guid;

		}

		return 0;

	}


	const char* Gamepad::GetDeviceName (int id) {

		return SDL_GetGamepadName (gameControllers[id]);

	}


	void Gamepad::Rumble (int id, double lowFrequencyRumble, double highFrequencyRumble, int duration) {

		auto it = gameControllers.find (id);
		if (it == gameControllers.end ())
			return;

		if (highFrequencyRumble < 0.0f)
			highFrequencyRumble = 0.0f;
		else if (highFrequencyRumble > 1.0f)
			highFrequencyRumble = 1.0f;

		if (lowFrequencyRumble < 0.0f)
			lowFrequencyRumble = 0.0f;
		else if (lowFrequencyRumble > 1.0f)
			lowFrequencyRumble = 1.0f;

		SDL_RumbleGamepad (it->second, lowFrequencyRumble * 0xFFFF, highFrequencyRumble * 0xFFFF, duration);

	}


}