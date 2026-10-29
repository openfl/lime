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
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.ui.Menu)
@:access(lime.ui.MenuItem)
class NativeMenu
{
	public static inline var SUPPORT_POPUP:Int = 0x01;
	public static inline var SUPPORT_WINDOW:Int = 0x02;
	public static inline var SUPPORT_APPLICATION:Int = 0x04;

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
			if (item.keyEquivalent == keyCode
				&& item.submenu == null
				&& !item.isSeparator
				&& getModifierMask(item.keyEquivalentModifiers) == modifiers
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
				item.__keyEquivalent = cast keyCode;
				item.__keyEquivalentModifiers = cast keyModifiers;
			}

			if (flags & MENU_ITEM_ACTION != 0)
			{
				item.__systemAction = input.readString(input.readInt32());
			}

			if (flags & MENU_ITEM_SUBMENU != 0)
			{
				item.submenu = readMenu(input);
			}

			menu.addItem(item);
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
			items.push(item);

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

			output.writeInt32(items.length);
			output.writeInt32(flags);
			output.writeInt32(item.keyEquivalent);
			output.writeInt32(item.keyEquivalentModifiers);
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
