#include <ui/Haptic.h>

#import <AudioToolbox/AudioToolbox.h>


namespace lime {


	void Haptic::Vibrate (int period, int duration) {

		AudioServicesPlayAlertSound (kSystemSoundID_Vibrate);

	}


}