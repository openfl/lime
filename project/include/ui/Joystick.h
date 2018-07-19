#ifndef LIME_UI_JOYSTICK_H
#define LIME_UI_JOYSTICK_H


namespace lime {


	class Joystick {

		public:

			static const char* GetDeviceGUID (int id);
			static const char* GetDeviceName (int id);
			static int GetNumAxes (int id);
			static int GetNumButtons (int id);
			static int GetNumHats (int id);
			static int GetNumTrackballs (int id);

	};


}


#endif