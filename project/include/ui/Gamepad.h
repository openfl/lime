#ifndef LIME_UI_GAMEPAD_H
#define LIME_UI_GAMEPAD_H


namespace lime {


	class Gamepad {

		public:

			static void AddMapping (const char* content);
			static const char* GetDeviceGUID (int id);
			static const char* GetDeviceName (int id);
			static void Rumble (int id, double lowFrequencyRumble, double highFrequencyRumble, int duration);
			static int GetType (int id);
			static bool HasLED (int id);
			static bool HasRumbleTriggers (int id);
			static bool HasSensor (int id, int sensor);
			static bool RumbleTriggers (int id, double leftRumble, double rightRumble, int duration);
			static bool SetLED (int id, int red, int green, int blue);
			static bool SetSensorEnabled (int id, int sensor, bool enabled);

			// A virtual gamepad for Lime's tests, which keeps what it is told to do
			static int AttachVirtual ();
			static void DetachVirtual (int id);
			static bool GetVirtualOutput (int id, int* led, int* lowRumble, int* highRumble, int* leftRumble, int* rightRumble);

	};


}


#endif