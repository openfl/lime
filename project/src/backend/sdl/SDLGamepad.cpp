#include "SDLGamepad.h"


namespace lime {
	std::map<int, SDLGamepad> gameControllers;
	std::map<int, int> gameControllerIDs;
	
	SDLGamepad::SDLGamepad(SDL_GameController *_gameController) : gameController(_gameController) {
		// Get joystick from controller
		joystick = SDL_GameControllerGetJoystick(gameController);
		if (!joystick) {
			// Close joystick, since something has to be seriously wrong at this point
			SDL_GameControllerClose(gameController);
			gameController = nullptr;
			return;
		}
	}
	
	SDLGamepad::~SDLGamepad() {
		if (gameController != nullptr)
			SDL_GameControllerClose(gameController);
	}
	
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
		
		SDL_GameControllerRumble(gameController, smallStrength * 0xFFFF, largeStrength * 0xFFFF, duration);
	}

	// SDL static gamepad API
	bool SDLGamepad::Connect (int deviceID) {
		if (SDL_IsGameController (deviceID)) {
			SDL_GameController *gameController = SDL_GameControllerOpen(deviceID);
			
			if (gameController != nullptr) {
				SDL_Joystick *joystick = SDL_GameControllerGetJoystick(gameController);
				int id = SDL_JoystickInstanceID(joystick);

				gameControllers.emplace(std::pair<int, SDLGamepad>(id, SDLGamepad(gameController)));
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
		SDL_Joystick* joystick = SDL_GameControllerGetJoystick (gameControllers[id].gameController);

		if (joystick) {
			char* guid = new char[64];
			SDL_JoystickGetGUIDString (SDL_JoystickGetGUID (joystick), guid, 64);
			return guid;
		}

		return 0;

	}


	const char* Gamepad::GetDeviceName (int id) {
		return SDL_GameControllerName (gameControllers[id].gameController);
	}

	void Gamepad::Rumble (int id, int duration, double largeStrength, double smallStrength) {
		gameControllers[id].Rumble(duration, largeStrength, smallStrength);
	}
}