package lime._internal.backend.native;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Menu;
import lime.ui.MenuItem;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeApplication)
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.ui.Menu)
@:access(lime.ui.MenuItem)
class NativeMenu
{
	public static inline var SUPPORT_POPUP:Int = 0x01;
	public static inline var SUPPORT_WINDOW:Int = 0x02;
	public static inline var SUPPORT_APPLICATION:Int = 0x04;

	// Where a menu belongs, as native_desktop::MenuSource numbers it
	public static inline var SOURCE_WINDOW:Int = 0;
	public static inline var SOURCE_TRAY_ICON:Int = 1;
	public static inline var SOURCE_APPLICATION:Int = 2;
	public static inline var SOURCE_DOCK:Int = 3;

	// The menu ID of the close event that follows the last menu to close
	private static inline var TRACKING_ENDED:Int = -1;

	// The menus installed or shown natively, by source and target, with the items their IDs index
	private static var installed = new Map<String, InstalledMenu>();
	private static var popups = new Map<String, InstalledMenu>();
	private static var registered = false;

	/**
		Writes the menu as little-endian Int32 values for the native menu backend:

		```
		menu := itemCount, item[itemCount]
		item := id, flags, keyCode, keyModifiers, labelLength, label,
		        [actionLength, action if flags & MENU_ITEM_ACTION], [menu if flags & MENU_ITEM_SUBMENU]
		```

		Labels are UTF-8, with "&" marking the mnemonic and "&&" for a literal
		ampersand. Each item is pushed to `items`, so that `id` is its index + 1.
		An action names what a standard item of the default menu bar does.
	**/
	public static function encode(menu:Menu, items:Array<MenuItem>):Bytes
	{
		var output = new BytesOutput();
		writeMenu(output, menu, items);
		return output.getBytes();
	}

	/**
		Reads a menu in the same format.
	**/
	public static function decode(bytes:Bytes):Menu
	{
		var input = new BytesInput(bytes);
		input.bigEndian = false;
		return readMenu(input);
	}

	/**
		A copy of the installed application menu bar, which on macOS starts with
		standard items, or `null` where there is none.
	**/
	public static function getApplicationMenu():Menu
	{
		#if (!macro && lime_cffi)
		var bytes:Bytes = NativeCFFI.lime_menu_get_application_menu(Bytes.alloc(0));
		return (bytes != null && bytes.length > 0) ? decode(bytes) : null;
		#else
		return null;
		#end
	}

	/**
		Starts dispatching `Menu.onOpen` and `Menu.onClose` from the native menus.
	**/
	public static function init():Void
	{
		#if (!macro && lime_cffi)
		if (registered) return;
		registered = true;
		NativeCFFI.lime_menu_set_open_callback(handleOpen);
		#end
	}

	/**
		Records the menu installed for a source and target, for its open and
		close events. `items` is the array its IDs index, which may grow while
		the menu is shown.
	**/
	public static function setInstalled(source:Int, target:Int, menu:Menu, items:Array<MenuItem>):Void
	{
		var key = source + ":" + target;

		if (menu != null && items != null) installed.set(key, {menu: menu, items: items});
		else installed.remove(key);
	}

	/**
		Records a menu shown at once, as a context menu, until its last close
		event. It takes the place of the installed menu of the same source and
		target meanwhile.
	**/
	public static function setPopup(source:Int, target:Int, menu:Menu, items:Array<MenuItem>):Void
	{
		popups.set(source + ":" + target, {menu: menu, items: items});
	}

	/**
		The array to encode a menu's items into before installing it. When the
		changes made while menus were shown are applied, a selection made in
		them may not have arrived yet, so the menu installed again keeps the IDs
		its items had.
	**/
	public static function newItems(source:Int, target:Int, menu:Menu):Array<MenuItem>
	{
		if (Menu.__applyingDeferred)
		{
			var context = installed.get(source + ":" + target);
			if (context != null && context.menu == menu) return context.items;
		}

		return [];
	}

	public static function handleClose(source:Int, target:Int, menuID:Int):Void
	{
		var key = source + ":" + target;

		if (menuID == TRACKING_ENDED)
		{
			popups.remove(key);
			Menu.__applyDeferred();
			return;
		}

		var menu = findMenu(key, menuID);
		if (menu != null) menu.onClose.dispatch();
	}

	private static function findMenu(key:String, menuID:Int):Menu
	{
		var context = popups.exists(key) ? popups.get(key) : installed.get(key);
		if (context == null) return null;
		if (menuID == 0) return context.menu;

		var item = getItem(context.items, menuID);
		return item != null ? item.submenu : null;
	}

	// Called by the native menus while a menu waits to be shown, where native code drops what is thrown
	private static function handleOpen():Void
	{
		#if (!macro && lime_cffi)
		try
		{
			dispatchOpen();
		}
		catch (exception:Dynamic)
		{
			NativeApplication.deferException(exception);
		}
		#end
	}

	private static function dispatchOpen():Void
	{
		#if (!macro && lime_cffi)
		var target:Int = NativeCFFI.lime_menu_get_open_event(0);
		var menuID:Int = NativeCFFI.lime_menu_get_open_event(1);
		var source:Int = NativeCFFI.lime_menu_get_open_event(2);
		var key = source + ":" + target;
		var context = popups.exists(key) ? popups.get(key) : installed.get(key);
		var menu = findMenu(key, menuID);

		if (menu == null) return;

		menu.__dispatchOpen();

		// The menu is built again from its items when they or its submenus changed. Items keep
		// their IDs, and new ones are added to the end, so the rest of the menu stays as it is.
		for (changed in Menu.__deferred)
		{
			if (changed.__isDescendantOf(menu))
			{
				var output = new BytesOutput();
				writeMenu(output, menu, context.items);
				NativeCFFI.lime_menu_set_open_items(output.getBytes());
				break;
			}
		}
		#end
	}

	public static function getItem(items:Array<MenuItem>, id:Int):MenuItem
	{
		return (items != null && id > 0 && id <= items.length) ? items[id - 1] : null;
	}

	public static function getKeyEquivalentItem(items:Array<MenuItem>, keyCode:KeyCode, modifier:KeyModifier):MenuItem
	{
		if (items == null || keyCode == UNKNOWN) return null;

		var modifiers = getModifierMask(modifier);

		for (item in items)
		{
			if (item.keyCode == keyCode
				&& item.submenu == null
				&& !item.isSeparator
				&& getModifierMask(item.keyModifier) == modifiers
				&& isEnabled(item))
			{
				return item;
			}
		}

		return null;
	}

	public static function getSupport():Int
	{
		#if (!macro && lime_cffi)
		return NativeCFFI.lime_menu_get_support();
		#else
		return 0;
		#end
	}

	private static function getLabel(item:MenuItem):String
	{
		var label = item.label;

		if (item.mnemonicIndex < 0 && label.indexOf("&") == -1)
		{
			return label;
		}

		var buffer = new StringBuf();

		for (i in 0...label.length)
		{
			if (i == item.mnemonicIndex) buffer.add("&");

			var char = label.charAt(i);
			buffer.add(char == "&" ? "&&" : char);
		}

		return buffer.toString();
	}

	private static function getModifierMask(modifier:KeyModifier):Int
	{
		var mask = 0;

		if (modifier.ctrlKey) mask |= KeyModifier.CTRL;
		if (modifier.shiftKey) mask |= KeyModifier.SHIFT;
		if (modifier.altKey) mask |= KeyModifier.ALT;
		if (modifier.metaKey) mask |= KeyModifier.META;

		return mask;
	}

	private static function isEnabled(item:MenuItem):Bool
	{
		while (item != null)
		{
			if (!item.enabled) return false;
			item = item.menu != null ? item.menu.parent : null;
		}

		return true;
	}

	private static function readMenu(input:BytesInput):Menu
	{
		var menu = new Menu();
		var count = input.readInt32();

		for (i in 0...count)
		{
			input.readInt32();
			var flags = input.readInt32();
			var keyCode = input.readInt32();
			var keyModifiers = input.readInt32();

			var item = new MenuItem("", flags & MENU_ITEM_SEPARATOR != 0);
			setLabel(item, input.readString(input.readInt32()));
			item.__enabled = flags & MENU_ITEM_ENABLED != 0;
			item.__checked = flags & MENU_ITEM_CHECKED != 0;

			if (keyCode != 0)
			{
				item.__keyCode = cast keyCode;
				item.__keyModifier = cast keyModifiers;
			}

			if (flags & MENU_ITEM_ACTION != 0)
			{
				item.__systemAction = input.readString(input.readInt32());
			}

			if (flags & MENU_ITEM_SUBMENU != 0)
			{
				item.submenu = readMenu(input);
			}

			menu.add(item);
		}

		return menu;
	}

	// The reverse of getLabel
	private static function setLabel(item:MenuItem, label:String):Void
	{
		var buffer = new StringBuf();
		var length = 0;
		var i = 0;

		while (i < label.length)
		{
			var char = label.charAt(i++);

			if (char == "&" && i < label.length)
			{
				char = label.charAt(i++);
				if (char != "&") item.__mnemonicIndex = length;
			}

			buffer.add(char);
			length++;
		}

		item.__label = buffer.toString();
	}

	private static function writeMenu(output:BytesOutput, menu:Menu, items:Array<MenuItem>):Void
	{
		output.writeInt32(menu.__items.length);

		for (item in menu.__items)
		{
			// An item already in items keeps its ID, as a menu built again while it is shown must
			var index = items.indexOf(item);

			if (index == -1)
			{
				items.push(item);
				index = items.length - 1;
			}

			var flags = 0;
			if (item.enabled) flags |= MENU_ITEM_ENABLED;
			if (item.checked) flags |= MENU_ITEM_CHECKED;

			if (item.isSeparator)
			{
				flags |= MENU_ITEM_SEPARATOR;
			}
			else if (item.submenu != null)
			{
				flags |= MENU_ITEM_SUBMENU;
			}

			if (item.__systemAction != null) flags |= MENU_ITEM_ACTION;

			var label = Bytes.ofString(getLabel(item));

			output.writeInt32(index + 1);
			output.writeInt32(flags);
			output.writeInt32(item.keyCode);
			output.writeInt32(item.keyModifier);
			output.writeInt32(label.length);
			output.write(label);

			if (flags & MENU_ITEM_ACTION != 0)
			{
				var action = Bytes.ofString(item.__systemAction);
				output.writeInt32(action.length);
				output.write(action);
			}

			if (flags & MENU_ITEM_SUBMENU != 0)
			{
				writeMenu(output, item.submenu, items);
			}
		}
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract MenuItemFlags(Int) from Int to Int
{
	var MENU_ITEM_ENABLED = 0x01;
	var MENU_ITEM_CHECKED = 0x02;
	var MENU_ITEM_SEPARATOR = 0x04;
	var MENU_ITEM_SUBMENU = 0x08;
	var MENU_ITEM_ACTION = 0x10;
}

private typedef InstalledMenu =
{
	var menu:Menu;
	var items:Array<MenuItem>;
}
