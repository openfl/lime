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

#if (cpp && windows)
@:buildXml('<target id="haxe"><lib name="gdi32.lib" if="windows" unless="mingw"/><lib name="-lgdi32" if="mingw"/></target>')
@:cppFileCode('
#include <windows.h>
#include <oleacc.h>
static HWND AppearanceTestWindow () {
 HWND result = NULL;
 EnumThreadWindows (GetCurrentThreadId (), [](HWND window, LPARAM data) -> BOOL {
  wchar_t title[80]; GetWindowTextW (window, title, 80);
  if (wcscmp (title, L"LimeMenuAppearanceTest") == 0) { *(HWND*)data = window; return FALSE; }
  return TRUE;
 }, (LPARAM)&result);
 return result;
}
static int InspectMenuAppearance (int operation) {
 HWND window = AppearanceTestWindow ();
 HMENU bar = window ? GetMenu (window) : NULL;
 HMENU menu = bar ? GetSubMenu (bar, 0) : NULL;
 if (!menu) return -1;
 MENUITEMINFOW info = {}; info.cbSize = sizeof (info);
 info.fMask = MIIM_FTYPE | MIIM_DATA | MIIM_STATE;
 if (!GetMenuItemInfoW (menu, 0, TRUE, &info)) return -2;
 if (operation == 0) return (info.fType & MFT_OWNERDRAW) != 0;
 if (operation == 1) {
  MSAAMENUINFO* accessible = (MSAAMENUINFO*)info.dwItemData;
  return accessible && accessible->dwMSAASignature == MSAA_MENU_SIG && accessible->cchWText == 4 && wcscmp (accessible->pszWText, L"Open") == 0;
 }
 if (operation == 2) {
  LRESULT result = SendMessageW (window, WM_MENUCHAR, MAKEWPARAM (L\'o\', MF_POPUP), (LPARAM)menu);
  return HIWORD (result) == MNC_EXECUTE && LOWORD (result) == 0;
 }
 if (operation == 3) {
  MEASUREITEMSTRUCT measure = {}; measure.CtlType = ODT_MENU; measure.itemData = info.dwItemData;
  return SendMessageW (window, WM_MEASUREITEM, 0, (LPARAM)&measure) && measure.itemWidth > 0 && measure.itemHeight > 0;
 }
 if (operation == 4) {
  HDC dc = CreateCompatibleDC (NULL); HBITMAP bitmap = CreateBitmap (200, 40, 1, 32, NULL);
  HGDIOBJ old = SelectObject (dc, bitmap);
  DRAWITEMSTRUCT draw = {}; draw.CtlType = ODT_MENU; draw.itemData = info.dwItemData;
  draw.hDC = dc; draw.hwndItem = (HWND)menu; SetRect (&draw.rcItem, 0, 0, 200, 40);
  LRESULT handled = SendMessageW (window, WM_DRAWITEM, 0, (LPARAM)&draw);
  COLORREF pixel = GetPixel (dc, 1, 1);
  SelectObject (dc, old); DeleteObject (bitmap); DeleteDC (dc);
  return handled && pixel == RGB (32, 32, 32);
 }
 if (operation == 5) return (info.fState & MFS_CHECKED) != 0;
 if (operation == 6) {
  SendMessageW (window, WM_THEMECHANGED, 0, 0);
  MENUITEMINFOW after = {}; after.cbSize = sizeof (after); after.fMask = MIIM_FTYPE;
  return GetMenuItemInfoW (menu, 0, TRUE, &after) && (after.fType & MFT_OWNERDRAW) != 0;
 }
 return -3;
}
')
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

	#if (cpp && windows)
	public function testWindowMenuAppearanceAndNativeInteraction():Void
	{
		// Tests run before the application's own window opens; keep one hidden window
		// alive so closing the window under test does not terminate the runner.
		var other = lime.app.Application.current.createWindow({width:64, height:64, hidden:true});
		var window = lime.app.Application.current.createWindow({width:320, height:160, hidden:true, title:"LimeMenuAppearanceTest"});
		Assert.notNull(window);
		if (window == null) return;
		var bar = new Menu();
		var items = new Menu();
		var open = items.addItem(new MenuItem("Open"));
		open.mnemonicIndex = 0;
		open.checked = true;
		items.addSeparator();
		var disabled = items.addItem(new MenuItem("Disabled"));
		disabled.enabled = false;
		bar.addSubmenu(items, "File").mnemonicIndex = 0;
		window.menu = bar;
		window.appearance = lime.ui.WindowAppearance.Light;
		Assert.equals(0, inspectAppearance(0));
		window.appearance = lime.ui.WindowAppearance.Dark;
		// High contrast must keep system rendering, without changing the user's settings.
		var contrast:Bool = untyped __cpp__('([]() { HIGHCONTRASTW value = {}; value.cbSize = sizeof(value); return SystemParametersInfoW(SPI_GETHIGHCONTRAST, sizeof(value), &value, 0) && (value.dwFlags & HCF_HIGHCONTRASTON); })()');
		Assert.equals(contrast ? 0 : 1, inspectAppearance(0));
		if (!contrast)
		{
			Assert.equals(1, inspectAppearance(1), "accessible name is exposed through MSAAMENUINFO");
			Assert.equals(1, inspectAppearance(2), "native mnemonic executes its item");
			Assert.equals(1, inspectAppearance(3), "native item measurement returns usable dimensions");
			Assert.equals(1, inspectAppearance(4), "native drawing fills the menu background");
			Assert.equals(1, inspectAppearance(6), "theme notifications retain an explicit dark preference");
		}
		Assert.equals(1, inspectAppearance(5), "checked state survives appearance changes");
		window.appearance = lime.ui.WindowAppearance.Light;
		Assert.equals(0, inspectAppearance(0), "light restores system drawing");
		window.appearance = lime.ui.WindowAppearance.Dark;
		items.addItem(new MenuItem("Another"));
		Assert.equals(contrast ? 0 : 1, inspectAppearance(0), "replaced native menus retain the preference");
		window.menu = null;
		var objectsBefore:Int = untyped __cpp__("GetGuiResources(GetCurrentProcess(), GR_GDIOBJECTS)");
		for (_ in 0...20)
		{
			window.menu = bar;
			window.appearance = lime.ui.WindowAppearance.Light;
			window.appearance = lime.ui.WindowAppearance.Dark;
			window.menu = null;
		}
		var objectsAfter:Int = untyped __cpp__("GetGuiResources(GetCurrentProcess(), GR_GDIOBJECTS)");
		Assert.isTrue(objectsAfter <= objectsBefore + 2, "menu replacement and appearance changes do not accumulate GDI resources");
		window.close();
	}

	private static function inspectAppearance(operation:Int):Int
	{
		return untyped __cpp__("InspectMenuAppearance({0})", operation);
	}
	#end

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
