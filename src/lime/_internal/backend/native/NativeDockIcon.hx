package lime._internal.backend.native;

import lime.graphics.Image;
import lime.ui.Menu;
import lime.ui.MenuItem;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.ui.MenuItem)
class NativeDockIcon
{
	private static var menuItems:Array<MenuItem>;

	public static function bounce(critical:Bool):Void
	{
		#if (!macro && lime_cffi)
		NativeCFFI.lime_dock_icon_bounce(critical);
		#end
	}

	public static function handleMenuSelect(id:Int):Void
	{
		var item = NativeMenu.getItem(menuItems, id);
		if (item != null) item.__select();
	}

	public static function isSupported():Bool
	{
		#if (!macro && lime_cffi)
		return NativeCFFI.lime_dock_icon_is_supported();
		#else
		return false;
		#end
	}

	public static function setIcon(image:Image):Void
	{
		#if (!macro && lime_cffi)
		NativeCFFI.lime_dock_icon_set_icon(NativeTrayIcon.getIconBuffer(image));
		#end
	}

	public static function setMenu(menu:Menu):Void
	{
		#if (!macro && lime_cffi)
		if (menu != null)
		{
			var items = [];
			var data = NativeMenu.encode(menu, items);
			menuItems = NativeCFFI.lime_dock_icon_set_menu(data) ? items : null;
		}
		else
		{
			NativeCFFI.lime_dock_icon_set_menu(null);
			menuItems = null;
		}
		#end
	}
}
