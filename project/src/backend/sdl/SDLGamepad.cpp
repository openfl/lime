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


	static SDL_GameController* GetController (int id) {

		auto it = gameControllers.find (id);
		return it != gameControllers.end () ? it->second : nullptr;

	}


	static Uint16 ToRumble (double value) {

		if (value < 0.0) value = 0.0;
		if (value > 1.0) value = 1.0;
		return (Uint16)(value * 0xFFFF);

	}


	int Gamepad::GetType (int id) {

		SDL_GameController* controller = GetController (id);
		return controller ? SDL_GameControllerGetType (controller) : SDL_CONTROLLER_TYPE_UNKNOWN;

	}


	bool Gamepad::HasLED (int id) {

		SDL_GameController* controller = GetController (id);
		return controller && SDL_GameControllerHasLED (controller) == SDL_TRUE;

	}


	bool Gamepad::HasRumbleTriggers (int id) {

		SDL_GameController* controller = GetController (id);
		return controller && SDL_GameControllerHasRumbleTriggers (controller) == SDL_TRUE;

	}


	bool Gamepad::HasSensor (int id, int sensor) {

		SDL_GameController* controller = GetController (id);
		return controller && SDL_GameControllerHasSensor (controller, (SDL_SensorType)sensor) == SDL_TRUE;

	}


	bool Gamepad::RumbleTriggers (int id, double leftRumble, double rightRumble, int duration) {

		SDL_GameController* controller = GetController (id);
		return controller && SDL_GameControllerRumbleTriggers (controller, ToRumble (leftRumble), ToRumble (rightRumble), duration) == 0;

	}


	bool Gamepad::SetLED (int id, int red, int green, int blue) {

		SDL_GameController* controller = GetController (id);
		return controller && SDL_GameControllerSetLED (controller, red, green, blue) == 0;

	}


	bool Gamepad::SetSensorEnabled (int id, int sensor, bool enabled) {

		SDL_GameController* controller = GetController (id);
		return controller && SDL_GameControllerSetSensorEnabled (controller, (SDL_SensorType)sensor, enabled ? SDL_TRUE : SDL_FALSE) == 0;

	}


	struct VirtualGamepadOutput {

		int led;
		int lowRumble;
		int highRumble;
		int leftRumble;
		int rightRumble;

	};


	static std::map<int, VirtualGamepadOutput*> virtualGamepads;


	static int SDLCALL VirtualRumble (void* userdata, Uint16 lowRumble, Uint16 highRumble) {

		VirtualGamepadOutput* output = (VirtualGamepadOutput*)userdata;
		output->lowRumble = lowRumble;
		output->highRumble = highRumble;
		return 0;

	}


	static int SDLCALL VirtualRumbleTriggers (void* userdata, Uint16 leftRumble, Uint16 rightRumble) {

		VirtualGamepadOutput* output = (VirtualGamepadOutput*)userdata;
		output->leftRumble = leftRumble;
		output->rightRumble = rightRumble;
		return 0;

	}


	static int SDLCALL VirtualSetLED (void* userdata, Uint8 red, Uint8 green, Uint8 blue) {

		VirtualGamepadOutput* output = (VirtualGamepadOutput*)userdata;
		output->led = (red << 16) | (green << 8) | blue;
		return 0;

	}


	int Gamepad::AttachVirtual () {

		VirtualGamepadOutput* output = new VirtualGamepadOutput ();
		output->led = -1;
		output->lowRumble = output->highRumble = output->leftRumble = output->rightRumble = -1;

		SDL_VirtualJoystickDesc desc;
		SDL_zero (desc);
		desc.version = SDL_VIRTUAL_JOYSTICK_DESC_VERSION;
		desc.type = SDL_JOYSTICK_TYPE_GAMECONTROLLER;
		desc.naxes = SDL_CONTROLLER_AXIS_MAX;
		desc.nbuttons = SDL_CONTROLLER_BUTTON_MAX;
		desc.name = "Lime Virtual Gamepad";
		desc.userdata = output;
		desc.Rumble = VirtualRumble;
		desc.RumbleTriggers = VirtualRumbleTriggers;
		desc.SetLED = VirtualSetLED;

		int deviceIndex = SDL_JoystickAttachVirtualEx (&desc);

		if (deviceIndex < 0 || !SDLGamepad::Connect (deviceIndex)) {

			if (deviceIndex >= 0) SDL_JoystickDetachVirtual (deviceIndex);
			delete output;
			return -1;

		}

		int id = SDLGamepad::GetInstanceID (deviceIndex);
		virtualGamepads[id] = output;
		return id;

	}


	void Gamepad::DetachVirtual (int id) {

		SDLGamepad::Disconnect (id);

		for (int i = 0; i < SDL_NumJoysticks (); i++) {

			if (SDL_JoystickIsVirtual (i) && SDL_JoystickGetDeviceInstanceID (i) == id) {

				SDL_JoystickDetachVirtual (i);
				break;

			}

		}

		auto it = virtualGamepads.find (id);

		if (it != virtualGamepads.end ()) {

			delete it->second;
			virtualGamepads.erase (it);

		}

	}


	bool Gamepad::GetVirtualOutput (int id, int* led, int* lowRumble, int* highRumble, int* leftRumble, int* rightRumble) {

		auto it = virtualGamepads.find (id);
		if (it == virtualGamepads.end ()) return false;

		*led = it->second->led;
		*lowRumble = it->second->lowRumble;
		*highRumble = it->second->highRumble;
		*leftRumble = it->second->leftRumble;
		*rightRumble = it->second->rightRumble;
		return true;

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
