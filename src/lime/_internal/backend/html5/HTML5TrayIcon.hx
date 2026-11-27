package lime._internal.backend.html5;

import lime.graphics.Image;
import lime.ui.Menu;
import lime.ui.TrayIcon;

class HTML5TrayIcon
{
	public function new(parent:TrayIcon) {}

	public function close():Void {}

	public static function isSupported():Bool
	{
		return false;
	}

	public function setIcon(image:Image):Void {}

	public function setMenu(menu:Menu):Void {}

	public function setTooltip(value:String):Void {}
}
