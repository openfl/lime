package js.html;

import js.html.Gamepad;

typedef GamepadEventInit =
{
	> EventInit,
	@:optional var gamepad : Gamepad;
}