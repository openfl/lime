#include "SDLGamepad.h"


namespace lime {


	std::map<int, SDL_Gamepad*> gamepads;
	std::map<int, int> gamepadIDs;


	bool SDLGamepad::Connect (int deviceID) {

		if (!SDL_IsGamepad (deviceID))
			return false;

		SDL_Gamepad *gamepad = SDL_OpenGamepad (deviceID);
		if (gamepad == nullptr)
			return false;

		SDL_Joystick *joystick = SDL_GetGamepadJoystick (gamepad);
		if (joystick == nullptr) {

			SDL_CloseGamepad (gamepad);
			return false;

		}

		int id = SDL_GetJoystickID (joystick);

		gamepads[id] = gamepad;
		gamepadIDs[deviceID] = id;

		return true;

	}


	bool SDLGamepad::Disconnect (int id) {

		auto it = gamepads.find (id);
		if (it == gamepads.end ())
			return false;

		SDL_CloseGamepad (it->second);
		gamepads.erase (id);

		for (auto iter = gamepadIDs.begin (); iter != gamepadIDs.end ();) {

			if (iter->second == id) {

				iter = gamepadIDs.erase (iter);

			} else {

				++iter;

			}

		}

		return true;

	}


	int SDLGamepad::GetInstanceID (int deviceID) {

		auto it = gamepadIDs.find (deviceID);
		return it == gamepadIDs.end () ? -1 : it->second;

	}


	void Gamepad::AddMapping (const char* content) {

		SDL_AddGamepadMapping (content);

	}


	const char* Gamepad::GetDeviceGUID (int id) {

		auto it = gamepads.find (id);
		if (it == gamepads.end ())
			return nullptr;

		SDL_Joystick* joystick = SDL_GetGamepadJoystick (it->second);
		if (joystick == nullptr)
			return nullptr;

		char* guid = new char[64];
		SDL_GUIDToString (SDL_GetJoystickGUID (joystick), guid, 64);
		return guid;

	}


	const char* Gamepad::GetDeviceName (int id) {

		auto it = gamepads.find (id);
		if (it == gamepads.end ())
			return nullptr;

		return SDL_GetGamepadName (it->second);

	}


	void Gamepad::Rumble (int id, double lowFrequencyRumble, double highFrequencyRumble, int duration) {

		auto it = gamepads.find (id);
		if (it == gamepads.end ())
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
