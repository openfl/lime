package flash.desktop;

@:native("flash.desktop.SystemIdleMode")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract SystemIdleMode(String)
{
	var KEEP_AWAKE;
	var NORMAL;
}
