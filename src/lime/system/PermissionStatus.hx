package lime.system;

/**
	Whether the user has allowed the application to use a device that the
	system asks about, such as the microphone.

	@see lime.media.AudioInput.permissionStatus
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract PermissionStatus(String) from String to String
{
	/**
		The user has not been asked yet, or the backend cannot tell.
	**/
	var UNDETERMINED = "undetermined";

	/**
		The user or the system has allowed it.
	**/
	var GRANTED = "granted";

	/**
		The user or the system has refused it.
	**/
	var DENIED = "denied";
}
