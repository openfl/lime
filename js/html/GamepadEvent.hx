package js.html;

import js.html.Gamepad;

@:native("GamepadEvent")
extern class GamepadEvent extends Event
{
	var gamepad(default,null) : Gamepad;
	var elapsedTime(default,null) : Float;
	var pseudoElement(default,null) : String;
	
	/** @throws DOMError */
	function new( type : String, ?eventInitDict : GamepadEventInit ) : Void;
}