#include "SDLGamepad.h"


namespace lime {


	std::map<int, SDLGamepad> gameControllers;
	std::map<int, int> gameControllerIDs;
	
	void SDLGamepad::Rumble(int duration, double largeStrength, double smallStrength) {
		// Make sure game controller is open
		if (gameController == nullptr)
			return;
		
		// Rumble controller
		if (smallStrength < 0.0f)
			smallStrength = 0.0f;
		else if (smallStrength > 1.0f)
			smallStrength = 1.0f;
		
		if (largeStrength < 0.0f)
			largeStrength = 0.0f;
		else if (largeStrength > 1.0f)
			largeStrength = 1.0f;
		
		if (duration < 0)
			duration = 0;
		else if (duration > 0xFFFF)
			duration = 0xFFFF;
		
		SDL_GameControllerRumble(gameController, largeStrength * 0xFFFF, smallStrength * 0xFFFF, duration);
	}

	// SDL static gamepad API

	bool SDLGamepad::Connect (int deviceID) {

		if (SDL_IsGameController (deviceID)) {

			SDL_GameController *gameController = SDL_GameControllerOpen(deviceID);
			
			if (gameController != nullptr) {

				SDL_Joystick *joystick = SDL_GameControllerGetJoystick(gameController);
				int id = SDL_JoystickInstanceID(joystick);

				gameControllers[id] = std::move(SDLGamepad(gameController));
				gameControllerIDs[deviceID] = id;

				return true;

			}

		}

		return false;

	}


	bool SDLGamepad::Disconnect (int id) {

		if (gameControllers.find(id) != gameControllers.end()) {

			gameControllers.erase(id);
			return true;

		}

		return false;

	}


	int SDLGamepad::GetInstanceID (int deviceID) {

		return gameControllerIDs[deviceID];

	}


	// Gamepad API
	void Gamepad::AddMapping (const char* content) {

		SDL_GameControllerAddMapping (content);

	}


	const char* Gamepad::GetDeviceGUID (int id) {
		auto it = gameControllers.find(id);
		if (it == gameControllers.end())
			return nullptr;
		
		SDL_Joystick* joystick = SDL_GameControllerGetJoystick (it->second.gameController);

		if (joystick) {

			char* guid = new char[64];
			SDL_JoystickGetGUIDString (SDL_JoystickGetGUID (joystick), guid, 64);
			return guid;

		}
		
		return nullptr;

	}


	const char* Gamepad::GetDeviceName (int id) {
		auto it = gameControllers.find(id);
		if (it == gameControllers.end())
			return nullptr;
		
		return SDL_GameControllerName(it->second.gameController);
	}

	void Gamepad::Rumble (int id, int duration, double largeStrength, double smallStrength) {
		auto it = gameControllers.find(id);
		if (it == gameControllers.end())
			return;
		
		it->second.Rumble(duration, largeStrength, smallStrength);
	}
}