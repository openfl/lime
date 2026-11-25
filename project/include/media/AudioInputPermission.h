#ifndef LIME_MEDIA_AUDIO_INPUT_PERMISSION_H
#define LIME_MEDIA_AUDIO_INPUT_PERMISSION_H


namespace lime {


	enum AudioInputPermissionStatus {

		AUDIO_INPUT_PERMISSION_UNDETERMINED = 0,
		AUDIO_INPUT_PERMISSION_GRANTED = 1,
		AUDIO_INPUT_PERMISSION_DENIED = 2

	};


	class AudioInputPermission {


		public:

			static int GetStatus ();
			static void Request ();


	};


}


#endif
