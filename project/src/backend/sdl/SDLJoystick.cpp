#include "SDLJoystick.h"

namespace lime
{

	static SDL_Joystick *accelerometer = 0;
	static SDL_JoystickID accelerometerID = -1;
	std::map<int, int> joystickIDs = std::map<int, int>();
	std::map<int, SDL_Joystick *> joysticks = std::map<int, SDL_Joystick *>();

	bool SDLJoystick::Connect(int deviceID)
	{

		if (deviceID != accelerometerID)
		{

			SDL_Joystick *joystick = SDL_OpenJoystick(deviceID);
			int id = SDL_GetJoystickInstanceID(joystick);

			if (joystick)
			{

				joysticks[id] = joystick;
				joystickIDs[deviceID] = id;
				return true;
			}
		}

		return false;
	}

	bool SDLJoystick::Disconnect(int id)
	{

		if (joysticks.find(id) != joysticks.end())
		{

			SDL_Joystick *joystick = joysticks[id];
			SDL_CloseJoystick(joystick);
			joysticks.erase(id);
			return true;
		}

		return false;
	}

	int SDLJoystick::GetInstanceID(int deviceID)
	{

		return joystickIDs[deviceID];
	}

	void SDLJoystick::Init()
	{

#if defined(IPHONE) || defined(ANDROID) || defined(TVOS)
		for (int i = 0; i < SDL_NumJoysticks(); i++)
		{

			if (strstr(SDL_JoystickNameForIndex(i), "Accelerometer"))
			{

				accelerometer = SDL_OpenJoystick(i);
				accelerometerID = SDL_GetJoystickInstanceID(accelerometer);
			}
		}
#endif
	}

	bool SDLJoystick::IsAccelerometer(int id)
	{

		return (id == accelerometerID);
	}

	const char *Joystick::GetDeviceGUID(int id)
	{

		char *guid = new char[64];
		SDL_GetJoystickGUIDString(SDL_GetJoystickGUID(joysticks[id]), guid, 64);
		return guid;
	}

	const char *Joystick::GetDeviceName(int id)
	{

		return SDL_GetJoystickName(joysticks[id]);
	}

	int Joystick::GetNumAxes(int id)
	{

		return SDL_GetNumJoystickAxes(joysticks[id]);
	}

	int Joystick::GetNumButtons(int id)
	{

		return SDL_GetNumJoystickButtons(joysticks[id]);
	}

	int Joystick::GetNumHats(int id)
	{

		return SDL_GetNumJoystickHats(joysticks[id]);
	}
}
