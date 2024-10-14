#ifndef LIME_UI_GAMEPAD_H
#define LIME_UI_GAMEPAD_H


namespace lime {


	class Gamepad {

		public:

			static void AddMapping (const char* content);
			static const char* GetDeviceGUID (int id);
			static const char* GetDeviceName (int id);
			
			static void Rumble(int id, int duration, double largeStrength, double smallStrength);

	};


}


#endif