#include "SDLGamepad.h"


namespace lime {


	std::map<int, SDL_GameController*> gameControllers;
	std::map<int, int> gameControllerIDs;


	bool SDLGamepad::Connect (int deviceID) {

		if (!SDL_IsGameController (deviceID))
			return false;

		SDL_GameController *gameController = SDL_GameControllerOpen (deviceID);
		if (gameController == nullptr)
			return false;

		SDL_Joystick *joystick = SDL_GameControllerGetJoystick (gameController);
		int id = SDL_JoystickInstanceID (joystick);

		gameControllers[id] = gameController;
		gameControllerIDs[deviceID] = id;

		return true;

	}


	bool SDLGamepad::Disconnect (int id) {

		auto it = gameControllers.find (id);
		if (it == gameControllers.end ())
			return false;

		SDL_GameControllerClose (it->second);
		gameControllers.erase (id);

		return true;

	}


	int SDLGamepad::GetInstanceID (int deviceID) {

		return gameControllerIDs[deviceID];

	}


	void Gamepad::AddMapping (const char* content) {

		SDL_GameControllerAddMapping (content);

	}


	const char* Gamepad::GetDeviceGUID (int id) {

		auto it = gameControllers.find (id);
		if (it == gameControllers.end ())
			return nullptr;

		SDL_Joystick* joystick = SDL_GameControllerGetJoystick (it->second);
		if (joystick == nullptr)
			return nullptr;

		char* guid = new char[64];
		SDL_JoystickGetGUIDString (SDL_JoystickGetGUID (joystick), guid, 64);
		return guid;

	}


	const char* Gamepad::GetDeviceName (int id) {

		auto it = gameControllers.find (id);
		if (it == gameControllers.end ())
			return nullptr;

		return SDL_GameControllerName (it->second);

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

		SDL_GameControllerRumble (it->second, lowFrequencyRumble * 0xFFFF, highFrequencyRumble * 0xFFFF, duration);

	}


}
