package lime.ui;

/**
	The kind of controller a `Gamepad` is, as for showing the right button
	prompts.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract GamepadType(Int) from Int to Int
{
	var UNKNOWN = 0;
	var XBOX_360 = 1;
	var XBOX_ONE = 2;
	var PS3 = 3;
	var PS4 = 4;
	var NINTENDO_SWITCH_PRO = 5;
	var VIRTUAL = 6;
	var PS5 = 7;
	var AMAZON_LUNA = 8;
	var GOOGLE_STADIA = 9;
	var NVIDIA_SHIELD = 10;
	var NINTENDO_SWITCH_JOYCON_LEFT = 11;
	var NINTENDO_SWITCH_JOYCON_RIGHT = 12;
	var NINTENDO_SWITCH_JOYCON_PAIR = 13;
}
