package flash.desktop;

@:native("flash.desktop.NotificationType")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract NotificationType(String)
{
	var CRITICAL;
	var INFORMATIONAL;
}
