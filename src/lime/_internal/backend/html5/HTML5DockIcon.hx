package lime._internal.backend.html5;

import lime.graphics.Image;
import lime.ui.Menu;

class HTML5DockIcon
{
	public static function bounce(critical:Bool):Void {}

	public static function isSupported():Bool
	{
		return false;
	}

	public static function setIcon(image:Image):Void {}

	public static function setMenu(menu:Menu):Void {}
}
