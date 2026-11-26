package ui;

import haxe.Timer;
import lime.app.Application;
import lime.ui.Menu;
import lime.ui.MenuItem;
import lime.ui.Window;
import utest.Assert;
import utest.Async;
import utest.Test;
#if (lime_cffi && !macro)
import haxe.io.BytesInput;
import lime._internal.backend.native.NativeMenu;
#end

/**
	`Menu.onOpen` comes before a menu is shown, while its items can still be
	changed, and `Menu.onClose` after it closes. Changes made in `onOpen` to
	other menus wait until the menus close.

	Native menus dispatch these through native-desktop, which Lime's own build
	gives the open and close events from native-desktop 1.2.0. With an older
	native-desktop the menus still work, without the events, and the test that
	shows a real menu says so and passes.
**/
class MenuOpenCloseTest extends Test
{
	public function new()
	{
		super();
	}

	public function teardown():Void
	{
		@:privateAccess Menu.__deferred = [];
		@:privateAccess Menu.__deferring = 0;
	}

	public function testChangesMadeWhileAMenuOpensWaitUntilItCloses():Void
	{
		var opening = new Menu();
		opening.add(new MenuItem("First"));
		var other = new Menu();
		var added = new MenuItem("Added");
		var heard = [];

		opening.onOpen.add(function()
		{
			heard.push("open");
			other.add(added);
			opening.add(new MenuItem("Second"));
		});

		@:privateAccess opening.__dispatchOpen();

		Assert.same(["open"], heard);
		// The items are added at once; only their installation waits
		Assert.equals(added, other.items[0]);
		Assert.equals(2, opening.items.length);
		Assert.isTrue(@:privateAccess Menu.__deferred.indexOf(other) > -1, "the change to the other menu was not held back");
		Assert.equals(0, @:privateAccess Menu.__deferring);

		@:privateAccess Menu.__applyDeferred();
		Assert.same([], @:privateAccess Menu.__deferred);
	}

	public function testAListenerThatThrowsDoesNotKeepHoldingChangesBack():Void
	{
		var menu = new Menu();
		menu.onOpen.add(function() throw "failed");

		try
		{
			@:privateAccess menu.__dispatchOpen();
		}
		catch (e:Dynamic) {}

		Assert.equals(0, @:privateAccess Menu.__deferring);
	}

	#if (lime_cffi && !macro)
	public function testEncodingAgainKeepsEachItemsID():Void
	{
		var menu = new Menu();
		var first = menu.add(new MenuItem("First"));
		var recent = new Menu();
		menu.addSubmenu("Recent", recent);
		var child = recent.add(new MenuItem("Child"));

		var items:Array<MenuItem> = [];
		NativeMenu.encode(menu, items);
		Assert.equals(3, items.length);

		// As onOpen does: an item put first, and one added to the submenu
		var inserted = menu.insert(0, new MenuItem("Inserted"));
		var grandchild = recent.add(new MenuItem("Grandchild"));
		var input = new BytesInput(NativeMenu.encode(menu, items));

		// The existing items keep their IDs, and new ones come after them
		Assert.equals(3, input.readInt32());
		Assert.equals(4, readItem(input));
		Assert.equals(1, readItem(input));
		Assert.equals(2, readItem(input));
		Assert.equals(2, input.readInt32());
		Assert.equals(3, readItem(input));
		Assert.equals(5, readItem(input));

		Assert.equals(first, NativeMenu.getItem(items, 1));
		Assert.equals(child, NativeMenu.getItem(items, 3));
		Assert.equals(inserted, NativeMenu.getItem(items, 4));
		Assert.equals(grandchild, NativeMenu.getItem(items, 5));
	}

	public function testAMenuInstalledAgainAfterItsChangesKeepsItsItems():Void
	{
		var menu = new Menu();
		menu.add(new MenuItem("First"));
		var items:Array<MenuItem> = [];
		NativeMenu.encode(menu, items);
		NativeMenu.setInstalled(NativeMenu.SOURCE_WINDOW, TARGET, menu, items);

		// A selection made in the menu can arrive after the changes are applied
		@:privateAccess Menu.__applyingDeferred = true;
		var again = NativeMenu.newItems(NativeMenu.SOURCE_WINDOW, TARGET, menu);
		var otherMenu = NativeMenu.newItems(NativeMenu.SOURCE_WINDOW, TARGET, new Menu());
		var otherTarget = NativeMenu.newItems(NativeMenu.SOURCE_TRAY_ICON, TARGET, menu);
		@:privateAccess Menu.__applyingDeferred = false;
		var later = NativeMenu.newItems(NativeMenu.SOURCE_WINDOW, TARGET, menu);

		NativeMenu.setInstalled(NativeMenu.SOURCE_WINDOW, TARGET, null, null);

		Assert.equals(items, again);
		Assert.same([], otherMenu);
		Assert.same([], otherTarget);
		Assert.notEquals(items, later);
	}

	public function testCloseEventsReachTheMenuThatClosed():Void
	{
		var bar = new Menu();
		var file = new Menu();
		file.add(new MenuItem("Open"));
		var fileItem = bar.addSubmenu("File", file);
		var edit = new Menu();
		edit.add(new MenuItem("Copy"));
		bar.addSubmenu("Edit", edit);

		var items:Array<MenuItem> = [];
		NativeMenu.encode(bar, items);
		NativeMenu.setInstalled(NativeMenu.SOURCE_WINDOW, TARGET, bar, items);

		var heard = [];
		bar.onClose.add(function() heard.push("bar"));
		file.onClose.add(function() heard.push("file"));
		edit.onClose.add(function() heard.push("edit"));

		menuEvent(MENU_CLOSE_WINDOW, TARGET, items.indexOf(fileItem) + 1);
		menuEvent(MENU_CLOSE_WINDOW, TARGET, 0);
		// Another window's menus, and the end of tracking, are not this one's
		menuEvent(MENU_CLOSE_WINDOW, TARGET + 1, 0);
		menuEvent(MENU_CLOSE_WINDOW, TARGET, -1);

		NativeMenu.setInstalled(NativeMenu.SOURCE_WINDOW, TARGET, null, null);

		Assert.same(["file", "bar"], heard);
	}

	public function testAContextMenuClosesInsteadOfTheInstalledMenu():Void
	{
		var installed = new Menu();
		installed.add(new MenuItem("Installed"));
		var installedItems:Array<MenuItem> = [];
		NativeMenu.encode(installed, installedItems);
		NativeMenu.setInstalled(NativeMenu.SOURCE_WINDOW, TARGET, installed, installedItems);

		var context = new Menu();
		context.add(new MenuItem("Context"));
		var contextItems:Array<MenuItem> = [];
		NativeMenu.encode(context, contextItems);
		NativeMenu.setPopup(NativeMenu.SOURCE_WINDOW, TARGET, context, contextItems);

		var heard = [];
		installed.onClose.add(function() heard.push("installed"));
		context.onClose.add(function() heard.push("context"));

		menuEvent(MENU_CLOSE_WINDOW, TARGET, 0);
		// Once tracking ends, the context menu is gone
		menuEvent(MENU_CLOSE_WINDOW, TARGET, -1);
		menuEvent(MENU_CLOSE_WINDOW, TARGET, 0);

		NativeMenu.setInstalled(NativeMenu.SOURCE_WINDOW, TARGET, null, null);

		Assert.same(["context", "installed"], heard);
	}

	public function testEachKindOfMenuClosesItsOwn():Void
	{
		var heard = [];
		var sources = [
			{type: MENU_CLOSE_WINDOW, source: NativeMenu.SOURCE_WINDOW, name: "window"},
			{type: MENU_CLOSE_TRAY_ICON, source: NativeMenu.SOURCE_TRAY_ICON, name: "tray icon"},
			{type: MENU_CLOSE_APPLICATION, source: NativeMenu.SOURCE_APPLICATION, name: "application"},
			{type: MENU_CLOSE_DOCK, source: NativeMenu.SOURCE_DOCK, name: "dock"}
		];

		for (entry in sources)
		{
			var menu = new Menu();
			menu.add(new MenuItem(entry.name));
			var name = entry.name;
			menu.onClose.add(function() heard.push(name));
			var items:Array<MenuItem> = [];
			NativeMenu.encode(menu, items);
			NativeMenu.setInstalled(entry.source, TARGET, menu, items);
		}

		for (entry in sources)
		{
			menuEvent(entry.type, TARGET, 0);
		}

		for (entry in sources)
		{
			NativeMenu.setInstalled(entry.source, TARGET, null, null);
		}

		Assert.same(["window", "tray icon", "application", "dock"], heard);
	}

	public function testTheEndOfTrackingAppliesHeldBackChanges():Void
	{
		var opening = new Menu();
		var other = new Menu();
		opening.onOpen.add(function() other.add(new MenuItem("Added")));

		@:privateAccess opening.__dispatchOpen();
		Assert.equals(1, @:privateAccess Menu.__deferred.length);

		menuEvent(MENU_CLOSE_WINDOW, TARGET, -1);
		Assert.same([], @:privateAccess Menu.__deferred);
	}

	#if windows
	private static var window:Window;

	/**
		Shows a real context menu, which a script closes by choosing its first
		item with the keyboard, as the user would. An item added first in onOpen
		is the one chosen.
	**/
	@:timeout(30000)
	public function testARealContextMenuOpensAndCloses(async:Async):Void
	{
		// The tests run before the application has opened its window. This one
		// is left open, hidden, as closing the last window ends the application
		if (window == null)
		{
			window = Application.current.createWindow({width: 64, height: 64, hidden: true, title: "MenuOpenCloseTest"});
		}

		if (window == null || !Menu.isSupported)
		{
			// Without a display, as on the Linux runners, no window can be created
			trace("No window with menus can be created here, so a real menu was not shown");
			Assert.pass();
			async.done();
			return;
		}

		var menu = new Menu();
		menu.add(new MenuItem("First"));
		menu.add(new MenuItem("Second"));

		var heard = [];
		menu.onOpen.add(function()
		{
			heard.push("open");
			menu.insert(0, new MenuItem("Added"));
		});
		menu.onSelect.add(function(item) heard.push("select " + item.label));
		menu.onClose.add(function() heard.push("close"));

		// Shown from the application's loop, as from an event or a timer, and not
		// from the constructor the tests start in
		Timer.delay(function()
		{
			var script = chooseFirstItem(window);

			// Returns once the menu has closed
			menu.popup(window, 10, 10);
			var closedByScript = script.exitCode() == 0;
			script.close();

			Timer.delay(function()
			{
				Assert.isTrue(closedByScript, "the menu was not found to choose from, and was canceled");

				if (heard.indexOf("open") == -1)
				{
					#if (native_desktop >= "1.2.0")
					Assert.fail("onOpen was not dispatched: " + heard.join(", "));
					#else
					// utest takes a warning as a failure, so the test passes, saying why
					trace("native-desktop " + haxe.macro.Compiler.getDefine("native-desktop")
						+ " has no menu open events, so only the menu itself was tested");
					Assert.isTrue(heard[0] == "select First", "heard " + heard.join(", "));
					#end
				}
				else
				{
					Assert.same(["open", "select Added", "close"], heard);
				}

				async.done();
			}, 500);
		}, 10);
	}

	/**
		What onOpen throws while a real context menu opens can't leave native code, which drops it, so
		it is thrown again from popup() once the menu closes, before the chosen item's onSelect (#2459).
	**/
	@:timeout(30000)
	public function testWhatOnOpenThrowsComesOutOfPopup(async:Async):Void
	{
		if (window == null)
		{
			window = Application.current.createWindow({width: 64, height: 64, hidden: true, title: "MenuOpenCloseTest"});
		}

		if (window == null || !Menu.isSupported)
		{
			trace("No window with menus can be created here, so a real menu was not shown");
			Assert.pass();
			async.done();
			return;
		}

		var menu = new Menu();
		menu.add(new MenuItem("First"));

		var opened = false;
		var selected = false;
		menu.onOpen.add(function()
		{
			opened = true;
			throw "thrown in onOpen";
		});
		menu.onSelect.add(function(item) selected = true);

		Timer.delay(function()
		{
			var script = chooseFirstItem(window);
			var thrown:Dynamic = null;

			try
			{
				menu.popup(window, 10, 10);
			}
			catch (e:Dynamic)
			{
				thrown = e;
			}

			var closedByScript = script.exitCode() == 0;
			script.close();

			// Nothing is left to come out of the application's own next update
			@:privateAccess lime._internal.backend.native.NativeApplication.deferredException = null;
			@:privateAccess lime._internal.backend.native.NativeApplication.deferredExceptionPending = false;

			Timer.delay(function()
			{
				Assert.isTrue(closedByScript, "the menu was not found to choose from, and was canceled");

				if (!opened)
				{
					// utest takes a warning as a failure, so the test passes, saying why
					trace("onOpen was not dispatched, as native-desktop " + haxe.macro.Compiler.getDefine("native-desktop")
						+ " here has no menu open events, so what it throws was not tested");
					Assert.pass();
				}
				else
				{
					Assert.equals("thrown in onOpen", Std.string(thrown), "what popup() threw");
					Assert.isFalse(selected, "onSelect was dispatched before what onOpen threw came out of popup()");
				}

				async.done();
			}, 500);
		}, 10);
	}

	/**
		Starts a script that finds the menu the window shows, and chooses its
		first item with the Down and Enter keys. When no menu shows, it cancels
		the menu mode so that the test goes on, and fails.
	**/
	private static function chooseFirstItem(window:Window):sys.io.Process
	{
		var hwnd = haxe.Int64.toStr(window.nativeHandle.window);
		var script = "Add-Type -Namespace LimeTest -Name Menus -MemberDefinition @'\n"
			+ "[DllImport(\"user32.dll\")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);\n"
			+ "[DllImport(\"user32.dll\")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);\n"
			+ "[DllImport(\"user32.dll\", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string className, string title);\n"
			+ "[DllImport(\"user32.dll\")] public static extern bool IsWindowVisible(IntPtr hWnd);\n"
			+ "public static IntPtr Find(IntPtr owner) {\n"
			+ "  uint process; uint thread = GetWindowThreadProcessId(owner, out process);\n"
			+ "  IntPtr menu = IntPtr.Zero;\n"
			+ "  while ((menu = FindWindowEx(IntPtr.Zero, menu, \"#32768\", null)) != IntPtr.Zero) {\n"
			+ "    uint other; if (GetWindowThreadProcessId(menu, out other) == thread && IsWindowVisible(menu)) return menu;\n"
			+ "  }\n"
			+ "  return IntPtr.Zero;\n"
			+ "}\n"
			+ "'@\n"
			+ "$owner = [IntPtr][Int64]" + hwnd + "\n"
			+ "$end = (Get-Date).AddSeconds(15)\n"
			+ "while ((Get-Date) -lt $end) {\n"
			+ "  $menu = [LimeTest.Menus]::Find($owner)\n"
			+ "  if ($menu -ne [IntPtr]::Zero) {\n"
			// WM_KEYDOWN with VK_DOWN, then VK_RETURN
			+ "    [LimeTest.Menus]::PostMessage($menu, 0x100, [IntPtr]0x28, [IntPtr]0) | Out-Null\n"
			+ "    [LimeTest.Menus]::PostMessage($menu, 0x100, [IntPtr]0x0D, [IntPtr]0) | Out-Null\n"
			+ "    exit 0\n"
			+ "  }\n"
			+ "  Start-Sleep -Milliseconds 50\n"
			+ "}\n"
			// WM_CANCELMODE ends the menu
			+ "[LimeTest.Menus]::PostMessage($owner, 0x1F, [IntPtr]0, [IntPtr]0) | Out-Null\n"
			+ "exit 1\n";

		// An encoded command is UTF-16, and needs no quoting
		var utf16 = haxe.io.Bytes.alloc(script.length * 2);
		for (i in 0...script.length)
		{
			utf16.setUInt16(i * 2, StringTools.fastCodeAt(script, i));
		}

		return new sys.io.Process(powerShell(), ["-NoProfile", "-NonInteractive", "-EncodedCommand", haxe.crypto.Base64.encode(utf16)]);
	}

	private static function powerShell():String
	{
		// HashLink starts a process by its path, without looking through PATH
		var root = Sys.getEnv("SystemRoot");
		var path = root != null ? root + "\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" : null;
		return path != null && sys.FileSystem.exists(path) ? path : "powershell";
	}
	#end

	// A window ID that no window has
	private static inline var TARGET = 0x3FFFF0;

	private static inline var MENU_CLOSE_WINDOW = 2;
	private static inline var MENU_CLOSE_TRAY_ICON = 3;
	private static inline var MENU_CLOSE_APPLICATION = 4;
	private static inline var MENU_CLOSE_DOCK = 5;

	private static function menuEvent(type:Int, windowID:Int, id:Int):Void
	{
		// The event as native code fills it in, then the handler it calls
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.menuEventInfo;
		info.type = cast type;
		info.windowID = windowID;
		info.id = id;
		@:privateAccess backend.handleMenuEvent();
	}

	private static function readItem(input:BytesInput):Int
	{
		// ID, flags, key code, modifiers, then the label's length and bytes
		var id = input.readInt32();
		input.readInt32();
		input.readInt32();
		input.readInt32();
		input.read(input.readInt32());
		return id;
	}
	#end

	#if (js && html5)
	public function testAContextMenuOpensWithItsChangesAndClosesOnEscape(async:Async):Void
	{
		withWindow(async, function(window)
		{
			var menu = new Menu();
			menu.add(new MenuItem("First"));

			var heard = [];
			menu.onOpen.add(function()
			{
				heard.push("open");
				menu.insert(0, new MenuItem("Added"));
			});
			menu.onClose.add(function() heard.push("close"));

			menu.popup(window, 10, 10);

			Assert.same(["open"], heard);
			Assert.same(["Added", "First"], panelLabels());

			key(27);
			Assert.same(["open", "close"], heard);
			Assert.same([], panelLabels());
		});
	}

	public function testChoosingAnItemClosesTheMenuFirst(async:Async):Void
	{
		withWindow(async, function(window)
		{
			var menu = new Menu();
			menu.add(new MenuItem("First"));

			var heard = [];
			menu.onClose.add(function() heard.push("close"));
			menu.onSelect.add(function(item) heard.push("select " + item.label));

			menu.popup(window, 10, 10);
			key(40);
			key(13);

			Assert.same(["close", "select First"], heard);
		});
	}

	public function testAMenuOfTheBarOpensAndTheBarDoesNot(async:Async):Void
	{
		withWindow(async, function(window)
		{
			var bar = new Menu();
			var file = new Menu();
			file.add(new MenuItem("Open"));
			bar.addSubmenu("File", file);
			var other = new Menu();
			other.add(new MenuItem("Other"));

			var heard = [];
			bar.onOpen.add(function() heard.push("bar open"));
			bar.onClose.add(function() heard.push("bar close"));
			file.onOpen.add(function()
			{
				heard.push("file open");
				// Held back until the menus close
				other.add(new MenuItem("Added"));
			});
			file.onClose.add(function() heard.push("file close"));

			window.menu = bar;

			try
			{
				var menus:Dynamic = @:privateAccess window.__backend.menus;
				var row:js.html.Element = menus.barRows[0];
				row.dispatchEvent(new js.html.MouseEvent("mousedown", {button: 0, bubbles: true, cancelable: true}));

				Assert.same(["file open"], heard);
				Assert.equals(1, @:privateAccess Menu.__deferred.length);

				key(27);
				Assert.same(["file open", "file close"], heard);
				Assert.same([], @:privateAccess Menu.__deferred);
			}
			catch (e:Dynamic)
			{
				window.menu = null;
				throw e;
			}

			window.menu = null;
		});
	}

	/**
		Runs `test` with the application's window, which the tests start before.
	**/
	private static function withWindow(async:Async, test:Window->Void):Void
	{
		var timer = new Timer(10);
		var started = false;
		timer.run = function()
		{
			// A run already queued can come after stop()
			if (started || Application.current.window == null) return;
			started = true;
			timer.stop();

			try
			{
				test(Application.current.window);
			}
			catch (e:Dynamic)
			{
				Assert.fail("" + e);
			}

			async.done();
		};
	}

	private static function key(keyCode:Int):Void
	{
		// keyCode cannot be given to the constructor
		var event = new js.html.KeyboardEvent("keydown", {bubbles: true, cancelable: true});
		js.Syntax.code("Object.defineProperty({0}, 'keyCode', {value: {1}})", event, keyCode);
		js.Browser.window.dispatchEvent(event);
	}

	private static function panelLabels():Array<String>
	{
		var labels = [];

		for (panel in js.Browser.document.querySelectorAll("body > .lime-menu"))
		{
			for (row in (cast panel : js.html.Element).querySelectorAll(".lime-menu-item"))
			{
				labels.push(StringTools.trim((cast row : js.html.Element).textContent));
			}
		}

		return labels;
	}
	#end
}
