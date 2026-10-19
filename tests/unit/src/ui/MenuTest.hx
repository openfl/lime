package ui;

import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Menu;
import lime.ui.MenuItem;
import utest.Assert;
import utest.Test;
#if (!flash && !js)
import haxe.io.BytesInput;
import lime._internal.backend.native.NativeMenu;
#end

class MenuTest extends Test
{
	public function new()
	{
		super();
	}

	public function testAddItemsInOrder():Void
	{
		var menu = new Menu();
		var first = menu.addItem(new MenuItem("First"));
		var third = menu.addItem(new MenuItem("Third"));
		var second = menu.addItemAt(new MenuItem("Second"), 1);

		Assert.equals(3, menu.numItems);
		Assert.equals(first, menu.getItemAt(0));
		Assert.equals(second, menu.getItemAt(1));
		Assert.equals(third, menu.getItemAt(2));
		Assert.equals(1, menu.getItemIndex(second));
		Assert.equals(menu, second.menu);
		Assert.isTrue(menu.containsItem(second));
		Assert.isNull(menu.getItemAt(3));
		Assert.isNull(menu.getItemAt(-1));
	}

	public function testAddItemAtClampsTheIndex():Void
	{
		var menu = new Menu();
		var last = menu.addItemAt(new MenuItem("Last"), 10);
		var first = menu.addItemAt(new MenuItem("First"), -5);

		Assert.equals(first, menu.getItemAt(0));
		Assert.equals(last, menu.getItemAt(1));
	}

	public function testAddingAnItemMovesIt():Void
	{
		var source = new Menu();
		var target = new Menu();
		var item = source.addItem(new MenuItem("Item"));

		target.addItem(item);

		Assert.equals(0, source.numItems);
		Assert.isFalse(source.containsItem(item));
		Assert.equals(target, item.menu);
	}

	public function testRemoveItems():Void
	{
		var menu = new Menu();
		var first = menu.addItem(new MenuItem("First"));
		var second = menu.addItem(new MenuItem("Second"));
		var third = menu.addItem(new MenuItem("Third"));

		Assert.equals(second, menu.removeItem(second));
		Assert.isNull(second.menu);
		Assert.isNull(menu.removeItem(second));
		Assert.equals(third, menu.removeItemAt(1));
		Assert.isNull(menu.removeItemAt(5));

		menu.removeAllItems();
		Assert.equals(0, menu.numItems);
		Assert.isNull(first.menu);
	}

	public function testSetItemIndexReorders():Void
	{
		var menu = new Menu();
		var first = menu.addItem(new MenuItem("First"));
		var second = menu.addItem(new MenuItem("Second"));

		menu.setItemIndex(second, 0);

		Assert.equals(second, menu.getItemAt(0));
		Assert.equals(first, menu.getItemAt(1));
		Assert.equals(2, menu.numItems);
	}

	public function testSeparatorsAndSubmenus():Void
	{
		var menu = new Menu();
		var separator = menu.addSeparator();
		var submenu = new Menu();
		var item = menu.addSubmenu(submenu, "More");

		Assert.isTrue(separator.isSeparator);
		Assert.equals(submenu, item.submenu);
		Assert.equals(item, submenu.parent);
		Assert.equals("More", item.label);
	}

	public function testMenuCannotContainItself():Void
	{
		var menu = new Menu();
		var submenu = new Menu();
		menu.addSubmenu(submenu, "Child");

		var item = new MenuItem("Loop");
		item.submenu = menu;

		Assert.raises(function() { submenu.addItem(item); });
		Assert.isNull(item.menu);
	}

	public function testItemDefaults():Void
	{
		var item = new MenuItem(null);

		Assert.equals("", item.label);
		Assert.isTrue(item.enabled);
		Assert.isFalse(item.checked);
		Assert.isFalse(item.isSeparator);
		Assert.equals(KeyCode.UNKNOWN, item.keyEquivalent);
		Assert.equals(-1, item.mnemonicIndex);
		Assert.isNull(item.submenu);
		Assert.equals(#if mac KeyModifier.META #else KeyModifier.CTRL #end, item.keyEquivalentModifiers);

		item.label = null;
		Assert.equals("", item.label);
	}

	public function testSelectBubblesToParentMenus():Void
	{
		var root = new Menu();
		var submenu = new Menu();
		root.addSubmenu(submenu, "Child");
		var item = submenu.addItem(new MenuItem("Item"));
		var calls:Array<String> = [];

		item.onSelect.add(function() calls.push("item"));
		submenu.onSelect.add(function(selected) calls.push("submenu " + selected.label));
		root.onSelect.add(function(selected) calls.push("root " + selected.label));

		@:privateAccess item.__select();

		Assert.same(["item", "submenu Item", "root Item"], calls);
	}

	public function testCancelingSelectStopsBubbling():Void
	{
		var root = new Menu();
		var submenu = new Menu();
		root.addSubmenu(submenu, "Child");
		var item = submenu.addItem(new MenuItem("Item"));
		var rootCalls = 0;

		submenu.onSelect.add(function(_) submenu.onSelect.cancel());
		root.onSelect.add(function(_) rootCalls++);

		@:privateAccess item.__select();
		Assert.equals(0, rootCalls);

		var itemCanceled = new Menu();
		var other = itemCanceled.addItem(new MenuItem("Other"));
		var menuCalls = 0;
		other.onSelect.add(function() other.onSelect.cancel());
		itemCanceled.onSelect.add(function(_) menuCalls++);

		@:privateAccess other.__select();
		Assert.equals(0, menuCalls);
	}

	public function testPopupWithoutAWindowDoesNothing():Void
	{
		var menu = new Menu();
		menu.addItem(new MenuItem("Item"));
		menu.popup(null);
		Assert.pass();
	}

	#if (!flash && !js)
	public function testNativeEncoding():Void
	{
		var menu = new Menu();
		var open = menu.addItem(new MenuItem("Open"));
		open.keyEquivalent = KeyCode.O;
		open.keyEquivalentModifiers = KeyModifier.CTRL;
		menu.addSeparator();

		var recent = new Menu();
		menu.addSubmenu(recent, "Recent");
		var child = recent.addItem(new MenuItem("x&y"));
		child.mnemonicIndex = 0;
		child.checked = true;
		child.enabled = false;

		var items:Array<MenuItem> = [];
		var input = new BytesInput(NativeMenu.encode(menu, items));

		Assert.equals(3, input.readInt32());
		assertItem(input, 1, 0x01, KeyCode.O, KeyModifier.CTRL, "Open");
		assertItem(input, 2, 0x01 | 0x04, KeyCode.UNKNOWN, menu.getItemAt(1).keyEquivalentModifiers, "");
		assertItem(input, 3, 0x01 | 0x08, KeyCode.UNKNOWN, menu.getItemAt(2).keyEquivalentModifiers, "Recent");
		Assert.equals(1, input.readInt32());
		assertItem(input, 4, 0x02, KeyCode.UNKNOWN, child.keyEquivalentModifiers, "&x&&y");
		Assert.equals(input.length, input.position);

		Assert.equals(4, items.length);
		Assert.equals(child, NativeMenu.getItem(items, 4));
		Assert.isNull(NativeMenu.getItem(items, 0));
		Assert.isNull(NativeMenu.getItem(items, 5));
	}

	public function testNativeKeyEquivalentLookup():Void
	{
		var menu = new Menu();
		var save = menu.addItem(new MenuItem("Save"));
		save.keyEquivalent = KeyCode.S;
		save.keyEquivalentModifiers = KeyModifier.CTRL;

		var submenu = new Menu();
		var parent = menu.addSubmenu(submenu, "More");
		var nested = submenu.addItem(new MenuItem("Nested"));
		nested.keyEquivalent = KeyCode.N;
		nested.keyEquivalentModifiers = KeyModifier.CTRL;

		var items:Array<MenuItem> = [];
		NativeMenu.encode(menu, items);

		Assert.equals(save, NativeMenu.getKeyEquivalentItem(items, KeyCode.S, KeyModifier.CTRL));
		Assert.isNull(NativeMenu.getKeyEquivalentItem(items, KeyCode.S, KeyModifier.SHIFT));
		Assert.equals(nested, NativeMenu.getKeyEquivalentItem(items, KeyCode.N, KeyModifier.CTRL));

		// A disabled item, or one in a disabled submenu, has no shortcut
		parent.enabled = false;
		Assert.isNull(NativeMenu.getKeyEquivalentItem(items, KeyCode.N, KeyModifier.CTRL));
		save.enabled = false;
		Assert.isNull(NativeMenu.getKeyEquivalentItem(items, KeyCode.S, KeyModifier.CTRL));
	}

	private function assertItem(input:BytesInput, id:Int, flags:Int, keyCode:Int, modifiers:Int, label:String):Void
	{
		Assert.equals(id, input.readInt32());
		Assert.equals(flags, input.readInt32());
		Assert.equals(keyCode, input.readInt32());
		Assert.equals(modifiers, input.readInt32());
		var length = input.readInt32();
		Assert.equals(label, input.readString(length));
	}
	#end
}
