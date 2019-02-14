package flash.desktop;

extern class SystemTrayIcon extends InteractiveIcon
{
	var menu:flash.display.NativeMenu;
	var tooltip:String;
	function new():Void;
	static var MAX_TIP_LENGTH(default, never):Float;
}
