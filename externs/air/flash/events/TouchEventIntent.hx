package flash.events;

@:native("flash.events.TouchEventIntent")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract TouchEventIntent(String)
{
	var ERASER;
	var PEN;
	var UNKNOWN;
}
