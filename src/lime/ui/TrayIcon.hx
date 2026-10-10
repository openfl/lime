package lime.ui;

import lime.app.Event;
import lime.graphics.Image;

/**
	An icon in the system tray, with an optional menu. Tray icons are shown in
	the notification area on Windows, in the menu bar on macOS, and as status
	notifier items on Linux.

	Example usage:
	```haxe
	if (TrayIcon.isSupported)
	{
		var trayIcon = new TrayIcon(Assets.getImage("icon.png"), "My App");
		trayIcon.onClick.add(() -> window.focus());

		var menu = new Menu();
		menu.addItem(new MenuItem("Show")).onSelect.add(() -> window.focus());
		menu.addSeparator();
		menu.addItem(new MenuItem("Quit")).onSelect.add(() -> System.exit(0));
		trayIcon.menu = menu;
	}
	```

	Platform notes:

	- Windows: `onClick` is dispatched when the icon is clicked. When it is
	  right-clicked, `onRightClick` is dispatched, and then the menu is shown
	  unless the event was canceled.
	- macOS: when the icon has a menu, clicking it shows the menu. Otherwise,
	  `onClick` and `onRightClick` are dispatched.
	- Linux: requires AppIndicator (libayatana-appindicator3) and a desktop that
	  shows status notifier items. Clicking the icon shows its menu, and
	  `onClick` and `onRightClick` are not dispatched.

	A tray icon stays visible until `close()` is called or the application
	exits.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.ui.Menu)
class TrayIcon
{
	/**
		Whether tray icons are supported on the current platform.
	**/
	public static var isSupported(get, never):Bool;

	/**
		The image displayed for the icon, or `null` for the application icon.
	**/
	public var icon(get, set):Image;

	/**
		The menu for the icon, or `null` for none.
	**/
	public var menu(get, set):Menu;

	/**
		Dispatched when the icon is clicked. See the platform notes above.
	**/
	public var onClick(default, null) = new Event<Void->Void>();

	/**
		Dispatched when the icon is right-clicked. On Windows, canceling this
		event prevents the menu from being shown.
	**/
	public var onRightClick(default, null) = new Event<Void->Void>();

	/**
		The text shown when hovering over the icon (or its title on Linux).
	**/
	public var tooltip(get, set):String;

	@:noCompletion private static var __trayIcons:Array<TrayIcon> = [];

	@:noCompletion private var __backend:TrayIconBackend;
	@:noCompletion private var __icon:Image;
	@:noCompletion private var __menu:Menu;
	@:noCompletion private var __tooltip:String;

	public function new(icon:Image = null, tooltip:String = null)
	{
		__backend = new TrayIconBackend(this);

		// Keep open tray icons alive, since the platform shows them until they are closed
		__trayIcons.push(this);

		if (icon != null) this.icon = icon;
		if (tooltip != null) this.tooltip = tooltip;
	}

	/**
		Removes the icon from the system tray.
	**/
	public function close():Void
	{
		if (__menu != null)
		{
			__menu.__trayIcons.remove(this);
			__menu = null;
		}

		__trayIcons.remove(this);
		__backend.close();
	}

	@:noCompletion private static function __closeAll():Void
	{
		for (trayIcon in __trayIcons.copy())
		{
			trayIcon.close();
		}
	}

	// Get & Set Methods
	@:noCompletion private inline function get_icon():Image
	{
		return __icon;
	}

	@:noCompletion private function set_icon(value:Image):Image
	{
		__icon = value;
		__backend.setIcon(value);
		return value;
	}

	@:noCompletion private static function get_isSupported():Bool
	{
		return TrayIconBackend.isSupported();
	}

	@:noCompletion private inline function get_menu():Menu
	{
		return __menu;
	}

	@:noCompletion private function set_menu(value:Menu):Menu
	{
		if (value != __menu)
		{
			if (__menu != null) __menu.__trayIcons.remove(this);
			__menu = value;
			if (value != null) value.__trayIcons.push(this);

			__backend.setMenu(value);
		}

		return value;
	}

	@:noCompletion private inline function get_tooltip():String
	{
		return __tooltip;
	}

	@:noCompletion private function set_tooltip(value:String):String
	{
		__tooltip = value;
		__backend.setTooltip(value);
		return value;
	}
}

#if flash
@:noCompletion private typedef TrayIconBackend = lime._internal.backend.flash.FlashTrayIcon;
#elseif (js && html5)
@:noCompletion private typedef TrayIconBackend = lime._internal.backend.html5.HTML5TrayIcon;
#else
@:noCompletion private typedef TrayIconBackend = lime._internal.backend.native.NativeTrayIcon;
#end
