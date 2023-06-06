package flash.desktop;

@:native("flash.desktop.NotificationType")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract NotificationType(String)
{
	var CRITICAL;
	var INFORMATIONAL;
}
