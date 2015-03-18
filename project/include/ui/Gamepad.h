#ifndef LIME_UI_GAMEPAD_H
#define LIME_UI_GAMEPAD_H


namespace lime {
	
	
	class Gamepad {
		
		public:
			
			static const char* GetDeviceGUID (int id);
			static const char* GetDeviceName (int id);
		
	};
	
	
}


#endif