package lime._internal.backend.flash;

import lime.graphics.Image;
import lime.ui.Menu;

class FlashDockIcon
{
	public static function bounce(critical:Bool):Void {}

	public static function isSupported():Bool
	{
		return false;
	}

	public static function setIcon(image:Image):Void {}

	public static function setMenu(menu:Menu):Void {}
}
