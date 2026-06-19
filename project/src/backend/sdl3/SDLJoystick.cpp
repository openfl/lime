#include "SDLJoystick.h"


namespace lime {


	static SDL_Joystick* accelerometer = 0;
	static SDL_JoystickID accelerometerID = -1;
	std::map<int, int> joystickIDs = std::map<int, int> ();
	std::map<int, SDL_Joystick*> joysticks = std::map<int, SDL_Joystick*> ();


	bool SDLJoystick::Connect (int deviceID) {

		if (deviceID != accelerometerID) {

			SDL_Joystick* joystick = SDL_OpenJoystick (deviceID);
			if (joystick) {

				int id = SDL_GetJoystickID (joystick);
				joysticks[id] = joystick;
				joystickIDs[deviceID] = id;
				return true;

			}

		}

		return false;

	}


	bool SDLJoystick::Disconnect (int id) {

		if (joysticks.find (id) != joysticks.end ()) {

			SDL_Joystick* joystick = joysticks[id];
			SDL_CloseJoystick (joystick);
			joysticks.erase (id);

			for (auto iter = joystickIDs.begin (); iter != joystickIDs.end ();) {

				if (iter->second == id) {

					iter = joystickIDs.erase (iter);

				} else {

					++iter;

				}

			}

			return true;

		}

		return false;

	}


	int SDLJoystick::GetInstanceID (int deviceID) {

		auto it = joystickIDs.find (deviceID);
		return it == joystickIDs.end () ? -1 : it->second;

	}


	void SDLJoystick::Init () {

		#if defined(IPHONE) || defined(ANDROID) || defined(TVOS)
		int count = 0;
		SDL_JoystickID* devices = SDL_GetJoysticks (&count);

		for (int i = 0; i < count; i++) {

			const char* name = SDL_GetJoystickNameForID (devices[i]);
			if (name && strstr (name, "Accelerometer")) {

				accelerometer = SDL_OpenJoystick (devices[i]);
				if (accelerometer) {

					accelerometerID = SDL_GetJoystickID (accelerometer);

				}

			}

		}

		SDL_free (devices);
		#endif

	}


	bool SDLJoystick::IsAccelerometer (int id) {

		return (id == accelerometerID);

	}


	const char* Joystick::GetDeviceGUID (int id) {

		auto it = joysticks.find (id);
		if (it == joysticks.end ())
			return nullptr;

		char* guid = new char[64];
		SDL_GUIDToString (SDL_GetJoystickGUID (it->second), guid, 64);
		return guid;

	}


	const char* Joystick::GetDeviceName (int id) {

		auto it = joysticks.find (id);
		return it == joysticks.end () ? nullptr : SDL_GetJoystickName (it->second);

	}


	int Joystick::GetNumAxes (int id) {

		auto it = joysticks.find (id);
		return it == joysticks.end () ? 0 : SDL_GetNumJoystickAxes (it->second);

	}


	int Joystick::GetNumButtons (int id) {

		auto it = joysticks.find (id);
		return it == joysticks.end () ? 0 : SDL_GetNumJoystickButtons (it->second);

	}


	int Joystick::GetNumHats (int id) {

		auto it = joysticks.find (id);
		return it == joysticks.end () ? 0 : SDL_GetNumJoystickHats (it->second);

	}


}
