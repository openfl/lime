package flash.desktop;

extern class DockIcon extends InteractiveIcon
{
	var menu:flash.display.NativeMenu;
	function new():Void;
	function bounce(?priority:NotificationType = NotificationType.INFORMATIONAL):Void;
}
