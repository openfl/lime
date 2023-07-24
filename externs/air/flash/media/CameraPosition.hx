package flash.media;

@:native("flash.media.CameraPosition")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract CameraPosition(String)
{
	var BACK;
	var FRONT;
	var UNKNOWN;
}
