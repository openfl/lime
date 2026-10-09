package lime.ui;

import lime.graphics.Image;

/**
	The application's icon in the macOS Dock.

	The Dock icon can show a custom image, add items to the menu shown when
	the icon is right-clicked, and bounce to request the user's attention.

	Example usage:
	```haxe
	if (DockIcon.isSupported)
	{
		var menu = new Menu();
		menu.addItem(new MenuItem("New Window")).onSelect.add(() -> createWindow());
		DockIcon.menu = menu;

		DockIcon.bounce();
	}
	```

	Availability note: the Dock only exists on macOS. Elsewhere, the Dock icon
	can be configured, but nothing is displayed.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.ui.Menu)
class DockIcon
{
	/**
		Whether the application has a Dock icon.
	**/
	public static var isSupported(get, never):Bool;

	/**
		The image shown in the Dock, or `null` for the application icon.
	**/
	public static var icon(get, set):Image;

	/**
		A menu whose items are added to the Dock icon's menu, above the items
		provided by macOS, or `null` for none.
	**/
	public static var menu(get, set):Menu;

	@:noCompletion private static var __icon:Image;
	@:noCompletion private static var __menu:Menu;

	/**
		Bounces the Dock icon to request the user's attention while the
		application is not active. A critical request keeps bouncing until the
		application is activated, otherwise the icon bounces once.
	**/
	public static function bounce(critical:Bool = false):Void
	{
		DockIconBackend.bounce(critical);
	}

	@:noCompletion private static function __update():Void
	{
		DockIconBackend.setMenu(__menu);
	}

	// Get & Set Methods
	@:noCompletion private static inline function get_icon():Image
	{
		return __icon;
	}

	@:noCompletion private static function set_icon(value:Image):Image
	{
		__icon = value;
		DockIconBackend.setIcon(value);
		return value;
	}

	@:noCompletion private static function get_isSupported():Bool
	{
		return DockIconBackend.isSupported();
	}

	@:noCompletion private static inline function get_menu():Menu
	{
		return __menu;
	}

	@:noCompletion private static function set_menu(value:Menu):Menu
	{
		if (value != __menu)
		{
			if (__menu != null) __menu.__dockIcon = false;
			__menu = value;
			if (value != null) value.__dockIcon = true;

			DockIconBackend.setMenu(value);
		}

		return value;
	}
}

#if (lime_cffi && !macro)
@:noCompletion private typedef DockIconBackend = lime._internal.backend.native.NativeDockIcon;
#else
@:noCompletion private class DockIconBackend
{
	public static function bounce(critical:Bool):Void {}

	public static function isSupported():Bool
	{
		return false;
	}

	public static function setIcon(image:Image):Void {}

	public static function setMenu(menu:Menu):Void {}
}
#end
