package lime.ui;

import lime.app.Application;
import lime.app.Event;

/**
	A native menu, displayed as a menu bar or as a context menu using
	`popup()`.

	Menus contain `MenuItem` objects, which may in turn hold submenus. Changes
	to a menu that is currently displayed are applied to the native menu
	immediately.
	Windows menus follow the owning window's explicit `appearance` preference,
	with system rendering in high contrast mode. Tray menus follow the system.
	macOS context menus inherit their owning view's appearance; the application
	menu bar and tray retain system styling. GTK context menus request the current
	theme's variant without changing global settings. Themes may lack a dark variant.

	Where the menu bar is shown depends on the platform: on Windows each window
	has its own menu bar (`Window.menu`), while on macOS the menu bar belongs to
	the application (`Application.menu`).

	Example usage:
	```haxe
	var fileMenu = new Menu();

	var openItem = fileMenu.add(new MenuItem("Open..."));
	openItem.keyCode = KeyCode.O;
	openItem.onSelect.add(() -> trace("Open"));

	fileMenu.addSeparator();
	fileMenu.add(new MenuItem("Exit")).onSelect.add(() -> window.close());

	var menuBar = new Menu();
	menuBar.addSubmenu("File", fileMenu).mnemonicIndex = 0;

	if (Window.supportsMenu)
	{
		window.menu = menuBar;
	}
	else if (Application.supportsMenu)
	{
		application.menu = menuBar;
	}
	```

	Availability note: native menus are implemented on Windows and macOS. On
	Linux, context menus are available when GTK 3 is installed and SDL uses X11.
	On HTML5, menu bars and context menus are drawn in the page, following the
	window's `appearance`, and can be restyled with the `lime-menu` CSS classes.
	Elsewhere, menus can be created and assigned, but are not displayed.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.app.Application)
@:access(lime.ui.DockIcon)
@:access(lime.ui.MenuItem)
@:access(lime.ui.TrayIcon)
@:access(lime.ui.Window)
class Menu
{
	/**
		Whether any form of native menu is supported on the current platform.
		See `Window.supportsMenu` and `Application.supportsMenu` for menu bars.
	**/
	public static var isSupported(get, never):Bool;

	/**
		A copy of the items in this menu.
	**/
	public var items(get, never):Array<MenuItem>;

	/**
		Dispatched when this menu closes, whether an item was selected or not,
		as when a context menu is dismissed. It comes after the menu has
		closed, so it cannot change what was shown.

		Available where `onOpen` is.
	**/
	public var onClose(default, null) = new Event<Void->Void>();

	/**
		Dispatched when this menu is about to be shown, before it appears, so
		its items can still be changed: enabled, checked, relabeled, added or
		removed. A menu bar dispatches it for each of its menus as they drop
		down, and a submenu as it opens; the menu bar itself does not.

		Changes to other menus made here wait until the menus close.

		Available on Windows and macOS for menu bars, context menus and tray
		icon menus, on Linux for context menus and their submenus, and on
		HTML5. Linux tray icon menus are shown by the desktop over D-Bus and do
		not dispatch it. On macOS, the menus of the menu bar are also prepared
		this way before a key equivalent is matched against them while they
		are closed, which does not dispatch it.
	**/
	public var onOpen(default, null) = new Event<Void->Void>();

	/**
		Dispatched when an item in this menu, or in one of its submenus, is
		selected. The innermost menu is notified first. Canceling this event
		prevents it from reaching the outer menus.
	**/
	public var onSelect(default, null) = new Event<MenuItem->Void>();

	/**
		The item that this menu is the submenu of, or `null`.
	**/
	public var parent(default, null):MenuItem;

	// Changes made while a menu is opening are applied once menus are no longer shown
	@:noCompletion private static var __applyingDeferred:Bool = false;
	@:noCompletion private static var __deferred:Array<Menu> = [];
	@:noCompletion private static var __deferring:Int = 0;

	@:noCompletion private var __application:Application;
	@:noCompletion private var __dockIcon:Bool;
	@:noCompletion private var __items:Array<MenuItem>;
	@:noCompletion private var __trayIcons:Array<TrayIcon>;
	@:noCompletion private var __windows:Array<Window>;

	public function new()
	{
		__dockIcon = false;
		__items = [];
		__trayIcons = [];
		__windows = [];
	}

	/**
		Adds an item to the end of the menu. If the item already belongs to a
		menu, it is removed from that menu first.
	**/
	public function add(item:MenuItem):MenuItem
	{
		return insert(__items.length, item);
	}

	/**
		Adds a separator to the end of the menu.
	**/
	public function addSeparator():MenuItem
	{
		return add(new MenuItem("", true));
	}

	/**
		Adds an item that displays `submenu` to the end of the menu.
	**/
	public function addSubmenu(label:String, submenu:Menu):MenuItem
	{
		var item = new MenuItem(label);
		item.submenu = submenu;
		return add(item);
	}

	/**
		Removes all items from the menu.
	**/
	public function clear():Void
	{
		for (item in __items)
		{
			item.menu = null;
		}

		__items = [];
		__update();
	}

	/**
		Adds an item at `index`, as `Array.insert` does. If the item already belongs
		to a menu, it is removed from that menu first, so this also moves an item
		within its menu.
	**/
	public function insert(index:Int, item:MenuItem):MenuItem
	{
		if (item == null) return null;

		if (item.__submenu != null && __isDescendantOf(item.__submenu))
		{
			throw "A menu cannot be a submenu of itself";
		}

		if (item.menu != null)
		{
			item.menu.remove(item);
		}

		if (index < 0) index = 0;
		if (index > __items.length) index = __items.length;

		__items.insert(index, item);
		item.menu = this;

		__update();
		return item;
	}

	/**
		Displays the menu as a context menu for `window`.

		`x` and `y` are in window coordinates. If either is omitted, the menu
		is displayed at the mouse cursor.

		This call blocks until the menu is dismissed, and the `onSelect` events
		of the chosen item are dispatched before it returns. To avoid the mouse
		button staying pressed, open context menus on mouse up. On HTML5, the
		call returns at once, and the events are dispatched when an item is
		chosen.
	**/
	public function popup(window:Window, ?x:Float, ?y:Float):Void
	{
		if (window != null)
		{
			window.__backend.popupMenu(this, x, y);
		}
	}

	/**
		Removes the item from the menu, and returns whether it was there.
	**/
	public function remove(item:MenuItem):Bool
	{
		if (!__items.remove(item)) return false;

		item.menu = null;

		__update();
		return true;
	}

	@:noCompletion private function __isDescendantOf(menu:Menu):Bool
	{
		var current = this;

		while (current != null)
		{
			if (current == menu) return true;
			current = current.parent != null ? current.parent.menu : null;
		}

		return false;
	}

	@:noCompletion private static function __applyDeferred():Void
	{
		if (__deferring > 0 || __deferred.length == 0) return;

		var menus = __deferred;
		__deferred = [];
		__applyingDeferred = true;

		try
		{
			for (menu in menus)
			{
				menu.__update();
			}
		}
		catch (e:Dynamic)
		{
			__applyingDeferred = false;
			throw e;
		}

		__applyingDeferred = false;
	}

	// Dispatches onOpen, holding back the updates the listeners make
	@:noCompletion private function __dispatchOpen():Void
	{
		__deferring++;

		try
		{
			onOpen.dispatch();
		}
		catch (e:Dynamic)
		{
			__deferring--;
			throw e;
		}

		__deferring--;
	}

	@:noCompletion private function __update():Void
	{
		if (__deferring > 0)
		{
			if (__deferred.indexOf(this) == -1) __deferred.push(this);
			return;
		}

		if (__application != null)
		{
			__application.__backend.setMenu(this);
		}

		if (__dockIcon)
		{
			DockIcon.__update();
		}

		for (trayIcon in __trayIcons)
		{
			trayIcon.__backend.setMenu(this);
		}

		for (window in __windows)
		{
			window.__backend.setMenu(this);
		}

		if (parent != null)
		{
			parent.__update();
		}
	}

	// Get & Set Methods
	@:noCompletion private static function get_isSupported():Bool
	{
		#if (lime_cffi && !macro)
		return lime._internal.backend.native.NativeMenu.getSupport() != 0;
		#elseif (js && html5)
		return true;
		#else
		return false;
		#end
	}

	@:noCompletion private function get_items():Array<MenuItem>
	{
		return __items.copy();
	}
}
