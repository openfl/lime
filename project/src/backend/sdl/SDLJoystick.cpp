#include "SDLJoystick.h"


namespace lime {


	static SDL_Joystick* accelerometer = 0;
	static SDL_JoystickID accelerometerID = -1;
	std::map<int, SDL_Joystick*> joysticks = std::map<int, SDL_Joystick*> ();


	bool SDLJoystick::Connect (int id) {

		if (id != accelerometerID) {

			SDL_Joystick* joystick = SDL_JoystickOpen (id);

			if (joystick) {

				joysticks[id] = joystick;
				return true;

			}

		}

		return false;

	}


	bool SDLJoystick::Disconnect (int id) {

		if (joysticks.find (id) != joysticks.end ()) {

			SDL_Joystick* joystick = joysticks[id];
			SDL_JoystickClose (joystick);
			joysticks.erase (id);

			return true;

		}

		return false;

	}


	int SDLJoystick::GetInstanceID (int deviceID) {

		return SDL_JoystickInstanceID (joysticks[deviceID]);

	}


	void SDLJoystick::Init () {

		#if defined(IPHONE) || defined(ANDROID) || defined(TVOS)
		for (int i = 0; i < SDL_NumJoysticks (); i++) {

			if (strstr (SDL_JoystickNameForIndex (i), "Accelerometer")) {

				accelerometer = SDL_JoystickOpen (i);
				accelerometerID = SDL_JoystickInstanceID (accelerometer);

			}

		}
		#endif

	}


	bool SDLJoystick::IsAccelerometer (int id) {

		return (id == accelerometerID);

	}


	const char* Joystick::GetDeviceGUID (int id) {

		char* guid = new char[64];
		SDL_JoystickGetGUIDString (SDL_JoystickGetGUID (joysticks[id]), guid, 64);
		return guid;

	}


	const char* Joystick::GetDeviceName (int id) {

		return SDL_JoystickName (joysticks[id]);

	}


	int Joystick::GetNumAxes (int id) {

		return SDL_JoystickNumAxes (joysticks[id]);

	}


	int Joystick::GetNumButtons (int id) {

		return SDL_JoystickNumButtons (joysticks[id]);

	}


	int Joystick::GetNumHats (int id) {

		return SDL_JoystickNumHats (joysticks[id]);

	}


	int Joystick::GetNumTrackballs (int id) {

		return SDL_JoystickNumBalls (joysticks[id]);

	}


}
