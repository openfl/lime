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

#if (cpp && mac)
@:cppFileCode('#include <objc/runtime.h>
#include <objc/message.h>

// Asks AppKit directly, through the Objective-C runtime, what a click on the menu bar does

static id LimeTestSend (id target, const char* selector) {
	return ((id (*) (id, SEL)) objc_msgSend) (target, sel_registerName (selector));
}

static long LimeTestCount (id menu) {
	return ((long (*) (id, SEL)) objc_msgSend) (menu, sel_registerName ("numberOfItems"));
}

static id LimeTestItem (id menu, long index) {
	return ((id (*) (id, SEL, long)) objc_msgSend) (menu, sel_registerName ("itemAtIndex:"), index);
}

// Chooses the item of the application menu that carries action, as a click on it
// does, and returns its tag, or -1 when there is no such item
static int LimeTestChooseApplicationMenuItem (const char* action) {
	id application = LimeTestSend ((id) objc_getClass ("NSApplication"), "sharedApplication");
	id mainMenu = LimeTestSend (application, "mainMenu");
	if (!mainMenu || LimeTestCount (mainMenu) == 0) return -1;
	id appMenu = LimeTestSend (LimeTestItem (mainMenu, 0), "submenu");
	if (!appMenu) return -1;
	id name = ((id (*) (id, SEL, const char*)) objc_msgSend) ((id) objc_getClass ("NSString"), sel_registerName ("stringWithUTF8String:"), action);
	for (long i = 0; i < LimeTestCount (appMenu); i++) {
		id item = LimeTestItem (appMenu, i);
		id represented = LimeTestSend (item, "representedObject");
		if (represented && ((bool (*) (id, SEL, id)) objc_msgSend) (represented, sel_registerName ("isEqual:"), name)) {
			int tag = (int) ((long (*) (id, SEL)) objc_msgSend) (item, sel_registerName ("tag"));
			((void (*) (id, SEL, long)) objc_msgSend) (appMenu, sel_registerName ("performActionForItemAtIndex:"), i);
			return tag;
		}
	}
	return -1;
}')
// Lime is loaded as a library, so the tests link the Objective-C runtime themselves
@:buildXml('<target id="haxe"><lib name="-lobjc" /></target>')
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

	public function testNativeEncodingKeepsSystemActions():Void
	{
		var bar = new Menu();
		var app = new Menu();
		var quit = app.addItem(new MenuItem("Quit Tests"));
		quit.keyEquivalent = KeyCode.Q;
		quit.keyEquivalentModifiers = KeyModifier.META;
		@:privateAccess quit.__systemAction = "terminate:";
		var services = app.addSubmenu(new Menu(), "Services");
		@:privateAccess services.__systemAction = "services";
		app.addSeparator();
		var own = app.addItem(new MenuItem("Q&A"));
		own.mnemonicIndex = 0;
		bar.addSubmenu(app, "Tests");

		var copy = NativeMenu.decode(NativeMenu.encode(bar, []));
		var copyApp = copy.getItemAt(0).submenu;

		Assert.equals(1, copy.numItems);
		Assert.equals("Tests", copy.getItemAt(0).label);
		Assert.equals(4, copyApp.numItems);
		Assert.equals("Quit Tests", copyApp.getItemAt(0).label);
		Assert.equals("terminate:", @:privateAccess copyApp.getItemAt(0).__systemAction);
		Assert.equals(KeyCode.Q, copyApp.getItemAt(0).keyEquivalent);
		Assert.equals(KeyModifier.META, copyApp.getItemAt(0).keyEquivalentModifiers);
		Assert.equals("services", @:privateAccess copyApp.getItemAt(1).__systemAction);
		Assert.notNull(copyApp.getItemAt(1).submenu);
		Assert.isTrue(copyApp.getItemAt(2).isSeparator);
		Assert.isNull(@:privateAccess copyApp.getItemAt(3).__systemAction);
		Assert.equals("Q&A", copyApp.getItemAt(3).label);
		Assert.equals(0, copyApp.getItemAt(3).mnemonicIndex);
	}

	#if (mac && lime_cffi && !macro)
	public function testMacMenuStartsWithTheDefaultMenuBar():Void
	{
		var menu = lime.app.Application.current.menu;
		Assert.notNull(menu, "the menu starts as the default menu bar");
		if (menu == null) return;

		var appMenu = menu.getItemAt(0).submenu;
		Assert.notNull(appMenu, "the first item has the application menu");
		if (appMenu == null) return;

		var quit = findAction(appMenu, "terminate:");
		Assert.notNull(quit, "the application menu has Quit");
		if (quit != null)
		{
			Assert.equals(KeyCode.Q, quit.keyEquivalent);
			Assert.isTrue(quit.keyEquivalentModifiers.metaKey);
		}

		Assert.notNull(findAction(appMenu, "hide:"), "the application menu has Hide");
		Assert.notNull(findAction(appMenu, "services"), "the application menu has Services");
	}

	public function testMacDefaultItemsSurviveAddingAMenu():Void
	{
		var application = lime.app.Application.current;
		var menu = application.menu;
		Assert.notNull(menu, "the menu starts as the default menu bar");
		if (menu == null) return;

		var file = new Menu();
		file.addItem(new MenuItem("Open"));
		menu.addSubmenu(file, "File");

		// The menu bar is rebuilt from the Lime menu, and read back from macOS
		var native = NativeMenu.getApplicationMenu();

		application.menu = null;

		Assert.notNull(native);
		if (native == null) return;

		Assert.equals("File", native.getItemAt(native.numItems - 1).label);
		Assert.notNull(findAction(native, "terminate:"), "Quit still quits");
		Assert.notNull(findAction(native, "hide:"), "Hide still hides");
		Assert.notNull(findAction(native, "services"), "Services is still the Services menu");
		Assert.notNull(findAction(native, "windows"), "Window is still the Window menu");

		var restored = application.menu;
		Assert.notNull(restored, "setting null restores the default");
		if (restored != null) Assert.notEquals("File", restored.getItemAt(restored.numItems - 1).label);
	}

	#if cpp
	public function testMacChoosingAStandardItemSelectsTheLimeItem():Void
	{
		var application = lime.app.Application.current;
		var menu = application.menu;
		Assert.notNull(menu, "the menu starts as the default menu bar");
		if (menu == null) return;

		// With a menu of the application's own, the menu bar is Lime's
		var file = new Menu();
		file.addItem(new MenuItem("Open"));
		menu.addSubmenu(file, "File");

		var selected = 0;
		var showAll = findAction(menu.getItemAt(0).submenu, "unhideAllApplications:");
		if (showAll != null) showAll.onSelect.add(function() selected++);

		// Show All is chosen in the menu bar that macOS shows. It shows any hidden
		// applications, so it changes nothing on screen here.
		var tag:Int = untyped __cpp__('LimeTestChooseApplicationMenuItem ("unhideAllApplications:")');

		// Lime is told of it with the item's tag, as of any other item
		var backend = @:privateAccess application.__backend;
		var info = @:privateAccess backend.menuEventInfo;
		info.type = cast 0;
		info.windowID = 0;
		info.id = tag;
		@:privateAccess backend.handleMenuEvent();

		application.menu = null;

		Assert.notNull(showAll, "the application menu has Show All");
		Assert.isTrue(tag > 0, "the menu bar has Show All");
		Assert.equals(1, selected, "the Show All item of the Lime menu is selected");
	}
	#end

	private static function findAction(menu:Menu, action:String):MenuItem
	{
		for (item in menu.items)
		{
			if (@:privateAccess item.__systemAction == action) return item;

			if (item.submenu != null)
			{
				var found = findAction(item.submenu, action);
				if (found != null) return found;
			}
		}

		return null;
	}
	#end

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
