package flash.events;

@:native("flash.events.TouchEventIntent")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract TouchEventIntent(String)
{
	var ERASER;
	var PEN;
	var UNKNOWN;
}
