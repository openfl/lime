package flash.desktop;

@:native("flash.desktop.SystemIdleMode")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract SystemIdleMode(String)
{
	var KEEP_AWAKE;
	var NORMAL;
}
