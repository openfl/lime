#include <media/AudioInputPermission.h>


namespace lime {


	// Windows and Linux do not ask desktop applications. Android asks through
	// GameActivity, which Lime calls with JNI.

	int AudioInputPermission::GetStatus () {

		return AUDIO_INPUT_PERMISSION_GRANTED;

	}


	void AudioInputPermission::Request () {}


}
