package flash.desktop;

@:native("flash.desktop.NativeDragActions")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract NativeDragActions(String)
{
	var COPY;
	var LINK;
	var MOVE;
	var NONE;
}
