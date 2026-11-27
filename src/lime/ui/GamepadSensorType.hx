package lime.ui;

/**
	A motion sensor in a `Gamepad`.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract GamepadSensorType(Int) from Int to Int
{
	/**
		The accelerometer, read in metres per second squared.
	**/
	var ACCELEROMETER = 1;

	/**
		The gyroscope, read in radians per second.
	**/
	var GYROSCOPE = 2;

	/**
		The accelerometer of a left Joy-Con, or a Wii Nunchuk.
	**/
	var ACCELEROMETER_LEFT = 3;

	/**
		The gyroscope of a left Joy-Con.
	**/
	var GYROSCOPE_LEFT = 4;

	/**
		The accelerometer of a right Joy-Con.
	**/
	var ACCELEROMETER_RIGHT = 5;

	/**
		The gyroscope of a right Joy-Con.
	**/
	var GYROSCOPE_RIGHT = 6;
}
