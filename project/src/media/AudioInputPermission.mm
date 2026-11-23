#import <AVFoundation/AVFoundation.h>

#include <media/AudioInputPermission.h>


namespace lime {


	int AudioInputPermission::GetStatus () {

		#ifdef HX_MACOS
		if (@available (macOS 10.14, *)) {
		#endif

			switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]) {

				case AVAuthorizationStatusAuthorized: return AUDIO_INPUT_PERMISSION_GRANTED;
				case AVAuthorizationStatusDenied:
				case AVAuthorizationStatusRestricted: return AUDIO_INPUT_PERMISSION_DENIED;
				default: return AUDIO_INPUT_PERMISSION_UNDETERMINED;

			}

		#ifdef HX_MACOS
		}

		// Before 10.14, macOS did not ask
		return AUDIO_INPUT_PERMISSION_GRANTED;
		#endif

	}


	void AudioInputPermission::Request () {

		#ifdef HX_MACOS
		if (@available (macOS 10.14, *)) {
		#endif

			// Haxe polls GetStatus for the answer, so the handler has nothing to do
			[AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {}];

		#ifdef HX_MACOS
		}
		#endif

	}


}
