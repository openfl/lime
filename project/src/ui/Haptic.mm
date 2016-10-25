#include <ui/Haptic.h>

#import <AudioToolbox/AudioServices.h>


namespace lime {
	
	
	void Haptic::Vibrate (int period, int duration) {
		
		AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
		
	}
	
	
}