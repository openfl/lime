package lime.ui;

import lime.app.Event;

/**
	An item in a `Menu`. An item may be a command, a separator, or a label for
	a nested submenu.

	Changes to an item that is currently displayed are applied to the native
	menu immediately.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.ui.Menu)
class MenuItem
{
	/**
		Whether a check mark is displayed next to the item.
	**/
	public var checked(get, set):Bool;

	/**
		Whether the item can be selected. Disabled items are displayed grayed
		out, and their key equivalent is ignored.
	**/
	public var enabled(get, set):Bool;

	/**
		Whether the item is a separator line. Separators cannot be selected.
	**/
	public var isSeparator(default, null):Bool;

	/**
		A keyboard shortcut that selects the item while its menu is displayed as
		a menu bar, or `KeyCode.UNKNOWN` for none. The shortcut is also shown
		next to the label, including in context menus.
	**/
	public var keyEquivalent(get, set):KeyCode;

	/**
		The modifier keys that must be held with `keyEquivalent`. Defaults to
		`KeyModifier.CTRL` (`KeyModifier.META` on macOS). Left and right
		modifier keys are treated the same.
	**/
	public var keyEquivalentModifiers(get, set):KeyModifier;

	/**
		The text displayed for the item.
	**/
	public var label(get, set):String;

	/**
		The menu that contains this item, or `null`.
	**/
	public var menu(default, null):Menu;

	/**
		The index of the character in `label` that is used for keyboard
		navigation (underlined on Windows), or `-1` for none.
	**/
	public var mnemonicIndex(get, set):Int;

	/**
		Dispatched when the item is selected, before the `onSelect` event of
		each menu that contains it. Canceling this event prevents it from
		reaching the containing menus.
	**/
	public var onSelect(default, null) = new Event<Void->Void>();

	/**
		A menu that is displayed when this item is highlighted, or `null`.

		A menu can only be the submenu of one item at a time. Assigning a menu
		that is already a submenu removes it from its previous item.
	**/
	public var submenu(get, set):Menu;

	@:noCompletion private var __checked:Bool;
	@:noCompletion private var __enabled:Bool;
	@:noCompletion private var __keyEquivalent:KeyCode;
	@:noCompletion private var __keyEquivalentModifiers:KeyModifier;
	@:noCompletion private var __label:String;
	@:noCompletion private var __mnemonicIndex:Int;
	@:noCompletion private var __submenu:Menu;

	public function new(label:String = "", isSeparator:Bool = false)
	{
		__label = label != null ? label : "";
		this.isSeparator = isSeparator;

		__checked = false;
		__enabled = true;
		__keyEquivalent = UNKNOWN;
		__keyEquivalentModifiers = #if mac KeyModifier.META #else KeyModifier.CTRL #end;
		__mnemonicIndex = -1;
	}

	@:noCompletion private function __select():Void
	{
		onSelect.dispatch();
		if (onSelect.canceled) return;

		var current = menu;

		while (current != null)
		{
			current.onSelect.dispatch(this);
			if (current.onSelect.canceled) break;

			current = current.parent != null ? current.parent.menu : null;
		}
	}

	@:noCompletion private function __update():Void
	{
		if (menu != null) menu.__update();
	}

	// Get & Set Methods
	@:noCompletion private function get_checked():Bool
	{
		return __checked;
	}

	@:noCompletion private function set_checked(value:Bool):Bool
	{
		if (value != __checked)
		{
			__checked = value;
			__update();
		}

		return value;
	}

	@:noCompletion private function get_enabled():Bool
	{
		return __enabled;
	}

	@:noCompletion private function set_enabled(value:Bool):Bool
	{
		if (value != __enabled)
		{
			__enabled = value;
			__update();
		}

		return value;
	}

	@:noCompletion private function get_keyEquivalent():KeyCode
	{
		return __keyEquivalent;
	}

	@:noCompletion private function set_keyEquivalent(value:KeyCode):KeyCode
	{
		if (value != __keyEquivalent)
		{
			__keyEquivalent = value;
			__update();
		}

		return value;
	}

	@:noCompletion private function get_keyEquivalentModifiers():KeyModifier
	{
		return __keyEquivalentModifiers;
	}

	@:noCompletion private function set_keyEquivalentModifiers(value:KeyModifier):KeyModifier
	{
		if (value != __keyEquivalentModifiers)
		{
			__keyEquivalentModifiers = value;
			__update();
		}

		return value;
	}

	@:noCompletion private function get_label():String
	{
		return __label;
	}

	@:noCompletion private function set_label(value:String):String
	{
		if (value == null) value = "";

		if (value != __label)
		{
			__label = value;
			__update();
		}

		return value;
	}

	@:noCompletion private function get_mnemonicIndex():Int
	{
		return __mnemonicIndex;
	}

	@:noCompletion private function set_mnemonicIndex(value:Int):Int
	{
		if (value != __mnemonicIndex)
		{
			__mnemonicIndex = value;
			__update();
		}

		return value;
	}

	@:noCompletion private function get_submenu():Menu
	{
		return __submenu;
	}

	@:noCompletion private function set_submenu(value:Menu):Menu
	{
		if (value == __submenu) return value;

		if (value != null)
		{
			if (menu != null && menu.__isDescendantOf(value))
			{
				throw "A menu cannot be a submenu of itself";
			}

			if (value.parent != null)
			{
				value.parent.submenu = null;
			}
		}

		if (__submenu != null)
		{
			__submenu.parent = null;
		}

		__submenu = value;

		if (value != null)
		{
			value.parent = this;
		}

		__update();
		return value;
	}
}
