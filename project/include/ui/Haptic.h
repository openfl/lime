#ifndef LIME_UI_HAPTIC_H
#define LIME_UI_HAPTIC_H


namespace lime {
	
	
	class Haptic {
		
		public:
			#ifdef IPHONE
			static void Vibrate (int period, int duration);
			#endif

	};
	
	
}


#endif