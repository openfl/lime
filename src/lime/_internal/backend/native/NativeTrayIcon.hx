package lime._internal.backend.native;

import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.math.Vector2;
import lime.ui.Menu;
import lime.ui.MenuItem;
import lime.ui.TrayIcon;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.ui.Menu)
@:access(lime.ui.MenuItem)
@:access(lime.ui.TrayIcon)
class NativeTrayIcon
{
	private static var trayIconsByID = new Map<Int, NativeTrayIcon>();

	public var handle:Dynamic;

	private var id:Int;
	private var menuItems:Array<MenuItem>;
	private var menuShownByPlatform:Bool;
	private var parent:TrayIcon;

	public function new(parent:TrayIcon)
	{
		this.parent = parent;
		id = -1;

		#if (!macro && lime_cffi)
		handle = NativeCFFI.lime_tray_icon_create();

		if (handle != null)
		{
			id = NativeCFFI.lime_tray_icon_get_id(handle);
			trayIconsByID.set(id, this);
		}
		#end
	}

	public static function closeAll():Void
	{
		TrayIcon.__closeAll();
	}

	public static function getTrayIcon(id:Int):NativeTrayIcon
	{
		return trayIconsByID.get(id);
	}

	public static function isSupported():Bool
	{
		#if (!macro && lime_cffi)
		return NativeCFFI.lime_tray_icon_is_supported();
		#else
		return false;
		#end
	}

	public function close():Void
	{
		if (handle != null)
		{
			#if (!macro && lime_cffi)
			NativeCFFI.lime_tray_icon_close(handle);
			#end

			trayIconsByID.remove(id);
			handle = null;
			menuItems = null;
		}
	}

	public function handleClick():Void
	{
		parent.onClick.dispatch();
	}

	public function handleMenuSelect(itemID:Int):Void
	{
		var item = NativeMenu.getItem(menuItems, itemID);
		if (item != null) item.__select();
	}

	public function handleRightClick():Void
	{
		parent.onRightClick.dispatch();

		if (!parent.onRightClick.canceled && !menuShownByPlatform && parent.__menu != null)
		{
			popupMenu(parent.__menu);
		}
	}

	public function popupMenu(menu:Menu):Void
	{
		if (handle != null && menu != null)
		{
			#if (!macro && lime_cffi)
			var items = [];
			var data = NativeMenu.encode(menu, items);
			var item = NativeMenu.getItem(items, NativeCFFI.lime_tray_icon_popup_menu(handle, data));
			if (item != null) item.__select();
			#end
		}
	}

	public function setIcon(image:Image):Void
	{
		if (handle != null)
		{
			#if (!macro && lime_cffi)
			NativeCFFI.lime_tray_icon_set_icon(handle, getIconBuffer(image));
			#end
		}
	}

	public function setMenu(menu:Menu):Void
	{
		if (handle != null)
		{
			#if (!macro && lime_cffi)
			if (menu != null)
			{
				var items = [];
				var data = NativeMenu.encode(menu, items);
				menuItems = items;
				menuShownByPlatform = NativeCFFI.lime_tray_icon_set_menu(handle, data);
			}
			else
			{
				menuItems = null;
				menuShownByPlatform = NativeCFFI.lime_tray_icon_set_menu(handle, null);
			}
			#end
		}
	}

	public function setTooltip(value:String):Void
	{
		if (handle != null)
		{
			#if (!macro && lime_cffi)
			NativeCFFI.lime_tray_icon_set_tooltip(handle, value != null ? value : "");
			#end
		}
	}

	public static function getIconBuffer(image:Image):ImageBuffer
	{
		if (image == null || image.buffer == null) return null;

		var buffer = image.buffer;

		// Native icons are created from straight (non-premultiplied) RGBA pixels covering the whole buffer
		if (image.format == RGBA32 && !image.premultiplied && image.offsetX == 0 && image.offsetY == 0 && image.width == buffer.width
			&& image.height == buffer.height)
		{
			return buffer;
		}

		var copy = new Image(null, 0, 0, image.width, image.height, 0x00000000);
		copy.copyPixels(image, image.rect, new Vector2(0, 0));
		copy.format = RGBA32;
		copy.premultiplied = false;
		return copy.buffer;
	}
}
