package lime.media;

/**
	Which way a camera faces, from `CameraInputDevice.position`.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract CameraPosition(String) from String to String
{
	/**
		The camera faces the user, as a phone's selfie camera or a laptop's
		webcam does.
	**/
	var FRONT = "front";

	/**
		The camera faces away from the user, as a phone's main camera does.
	**/
	var BACK = "back";

	/**
		The system does not say, as for most desktop cameras.
	**/
	var UNKNOWN = "unknown";
}
