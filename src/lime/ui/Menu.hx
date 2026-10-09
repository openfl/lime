package lime.ui;

import lime.app.Application;
import lime.app.Event;

/**
	A native menu, displayed as a menu bar or as a context menu using
	`popup()`.

	Menus contain `MenuItem` objects, which may in turn hold submenus. Changes
	to a menu that is currently displayed are applied to the native menu
	immediately.

	Where the menu bar is shown depends on the platform: on Windows each window
	has its own menu bar (`Window.menu`), while on macOS the menu bar belongs to
	the application (`Application.menu`).

	Example usage:
	```haxe
	var fileMenu = new Menu();

	var openItem = fileMenu.addItem(new MenuItem("Open..."));
	openItem.keyEquivalent = KeyCode.O;
	openItem.onSelect.add(() -> trace("Open"));

	fileMenu.addSeparator();
	fileMenu.addItem(new MenuItem("Exit")).onSelect.add(() -> window.close());

	var menuBar = new Menu();
	menuBar.addSubmenu(fileMenu, "File").mnemonicIndex = 0;

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
	Elsewhere, menus can be created and assigned, but are not displayed.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.app.Application)
@:access(lime.ui.MenuItem)
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
		The number of items in this menu.
	**/
	public var numItems(get, never):Int;

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

	@:noCompletion private var __application:Application;
	@:noCompletion private var __items:Array<MenuItem>;
	@:noCompletion private var __windows:Array<Window>;

	public function new()
	{
		__items = [];
		__windows = [];
	}

	/**
		Adds an item to the end of the menu. If the item already belongs to a
		menu, it is removed from that menu first.
	**/
	public function addItem(item:MenuItem):MenuItem
	{
		return addItemAt(item, __items.length);
	}

	/**
		Adds an item at the specified index. If the item already belongs to a
		menu, it is removed from that menu first.
	**/
	public function addItemAt(item:MenuItem, index:Int):MenuItem
	{
		if (item == null) return null;

		if (item.__submenu != null && __isDescendantOf(item.__submenu))
		{
			throw "A menu cannot be a submenu of itself";
		}

		if (item.menu != null)
		{
			item.menu.removeItem(item);
		}

		if (index < 0) index = 0;
		if (index > __items.length) index = __items.length;

		__items.insert(index, item);
		item.menu = this;

		__update();
		return item;
	}

	/**
		Adds a separator to the end of the menu.
	**/
	public function addSeparator():MenuItem
	{
		return addItem(new MenuItem("", true));
	}

	/**
		Adds an item that displays `submenu` to the end of the menu.
	**/
	public function addSubmenu(submenu:Menu, label:String):MenuItem
	{
		return addSubmenuAt(submenu, __items.length, label);
	}

	/**
		Adds an item that displays `submenu` at the specified index.
	**/
	public function addSubmenuAt(submenu:Menu, index:Int, label:String):MenuItem
	{
		var item = new MenuItem(label);
		item.submenu = submenu;
		return addItemAt(item, index);
	}

	/**
		Whether the item belongs to this menu.
	**/
	public function containsItem(item:MenuItem):Bool
	{
		return item != null && item.menu == this;
	}

	/**
		Returns the item at the specified index, or `null`.
	**/
	public function getItemAt(index:Int):MenuItem
	{
		return (index >= 0 && index < __items.length) ? __items[index] : null;
	}

	/**
		Returns the index of the item, or `-1` if it is not in this menu.
	**/
	public function getItemIndex(item:MenuItem):Int
	{
		return __items.indexOf(item);
	}

	/**
		Displays the menu as a context menu for `window`.

		`x` and `y` are in window coordinates. If either is omitted, the menu
		is displayed at the mouse cursor.

		This call blocks until the menu is dismissed, and the `onSelect` events
		of the chosen item are dispatched before it returns. To avoid the mouse
		button staying pressed, open context menus on mouse up.
	**/
	public function popup(window:Window, ?x:Float, ?y:Float):Void
	{
		if (window != null)
		{
			window.__backend.popupMenu(this, x, y);
		}
	}

	/**
		Removes all items from the menu.
	**/
	public function removeAllItems():Void
	{
		for (item in __items)
		{
			item.menu = null;
		}

		__items = [];
		__update();
	}

	/**
		Removes the item from the menu.
	**/
	public function removeItem(item:MenuItem):MenuItem
	{
		var index = __items.indexOf(item);
		return index > -1 ? removeItemAt(index) : null;
	}

	/**
		Removes and returns the item at the specified index, or `null`.
	**/
	public function removeItemAt(index:Int):MenuItem
	{
		if (index < 0 || index >= __items.length) return null;

		var item = __items.splice(index, 1)[0];
		item.menu = null;

		__update();
		return item;
	}

	/**
		Moves the item to the specified index, adding it to the menu if needed.
	**/
	public function setItemIndex(item:MenuItem, index:Int):Void
	{
		addItemAt(item, index);
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

	@:noCompletion private function __update():Void
	{
		if (__application != null)
		{
			__application.__backend.setMenu(this);
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
		#else
		return false;
		#end
	}

	@:noCompletion private function get_items():Array<MenuItem>
	{
		return __items.copy();
	}

	@:noCompletion private function get_numItems():Int
	{
		return __items.length;
	}
}
