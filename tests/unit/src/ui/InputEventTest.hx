package ui;

import haxe.Int64;
import haxe.Timer;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import lime.app.Application;
import lime.app.Event;
import lime.system.System;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Menu;
import lime.ui.MenuItem;
import lime.ui.MouseButton;
import lime.ui.Touch;
import lime.ui.Window;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	Key, mouse, text and drop events are handed to the application as its event
	loop would, and are expected at the listeners of the window they name, with
	what SDL reports for them: the key code and SDL_Keymod bits of a key, the
	position, button and click count of a mouse button, the position and the
	relative motion of a mouse move, the steps of a wheel, the text typed or
	being composed, and the path of a dropped file. Key, mouse and touch events
	carry the time SDL took them in, as `Event.timestamp`.

	The fullscreen shortcut, Alt+Enter on Windows and Linux and Ctrl+Command+F
	on macOS, is the default action of its key press, so a listener that cancels
	the press stops it, as `preventDefault()` does for a Flash keyboard event.
**/
class InputEventTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && (windows || mac || linux) && !rpi)
	private static inline var KEY_DOWN = 0;
	private static inline var KEY_UP = 1;
	private static inline var MOUSE_DOWN = 0;
	private static inline var MOUSE_UP = 1;
	private static inline var MOUSE_MOVE = 2;
	private static inline var MOUSE_WHEEL = 3;
	private static inline var TOUCH_START = 0;
	private static inline var TOUCH_END = 1;
	private static inline var TOUCH_MOVE = 2;
	private static inline var TEXT_INPUT = 0;
	private static inline var TEXT_EDIT = 1;

	// SDL numbers windows from 1 as they are created
	private static inline var NO_WINDOW = 0x3FFFFF;

	private var window:Window;
	private var other:Window;
	private var reported:Bool = false;
	private var touchListeners:Array<Touch->Void> = [];

	public function teardown():Void
	{
		for (listener in touchListeners)
		{
			Touch.onStart.remove(listener);
			Touch.onMove.remove(listener);
			Touch.onEnd.remove(listener);
		}
		touchListeners = [];

		for (opened in [window, other])
		{
			if (opened == null) continue;

			opened.onKeyDown.removeAll();
			opened.onKeyUp.removeAll();
			opened.onMouseDown.removeAll();
			opened.onMouseUp.removeAll();
			opened.onMouseMove.removeAll();
			opened.onMouseMoveRelative.removeAll();
			opened.onMouseWheel.removeAll();
			opened.onTextInput.removeAll();
			opened.onTextEdit.removeAll();
			opened.onDropFile.removeAll();
			opened.preciseMouseWheel = false;

			if (opened.menu != null) opened.menu = null;
			if (opened.fullscreen) opened.fullscreen = false;
		}
	}

	public function testAKeyPressReachesItsWindowWithItsCodeAndModifier():Void
	{
		var window = open();
		if (window == null) return;

		var presses = [], releases = 0;
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) presses.push(code(keyCode) + "," + bits(modifier)));
		window.onKeyUp.add(function(keyCode:KeyCode, modifier:KeyModifier) releases++);

		key(KEY_DOWN, window.id, KeyCode.A, KeyModifier.LEFT_SHIFT);

		Assert.equals("97,1", presses.join("|"));
		Assert.equals(0, releases);
	}

	public function testAKeyReleaseReachesItsWindowWithItsCodeAndModifier():Void
	{
		var window = open();
		if (window == null) return;

		var releases = [], presses = 0;
		window.onKeyUp.add(function(keyCode:KeyCode, modifier:KeyModifier) releases.push(code(keyCode) + "," + bits(modifier)));
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) presses++);

		key(KEY_UP, window.id, KeyCode.Z, KeyModifier.RIGHT_CTRL);

		Assert.equals("122,128", releases.join("|"));
		Assert.equals(0, presses);
	}

	public function testKeysWithoutACharacterKeepTheirCode():Void
	{
		var window = open();
		if (window == null) return;

		// Their codes have bit 30 set, which is past what a Neko integer holds unboxed
		var keyCodes:Array<KeyCode> = [CAPS_LOCK, F1, RIGHT, NUMPAD_ENTER, LEFT_CTRL, RIGHT_META, SLEEP];
		var expected:Array<Int> = [for (keyCode in keyCodes) keyCode];
		var received:Array<Int> = [];
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) received.push(keyCode));
		window.onKeyUp.add(function(keyCode:KeyCode, modifier:KeyModifier) received.push(keyCode));

		for (keyCode in keyCodes)
		{
			key(KEY_DOWN, window.id, keyCode, KeyModifier.NONE);
		}

		key(KEY_UP, window.id, KeyCode.SLEEP, KeyModifier.NONE);
		expected.push(KeyCode.SLEEP);

		Assert.equals(expected.join(","), received.join(","));
		Assert.isTrue(received[1] == KeyCode.F1);
	}

	public function testEveryModifierBitOfAKeyIsKept():Void
	{
		var window = open();
		if (window == null) return;

		var modifiers = [for (bit in 0...16) 1 << bit];
		modifiers.push(0xFFFF);
		var received:Array<Int> = [];
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) received.push(modifier));

		for (modifier in modifiers)
		{
			key(KEY_DOWN, window.id, KeyCode.A, modifier);
		}

		Assert.equals(modifiers.join(","), received.join(","));
	}

	public function testAKeysModifierReadsAsTheKeysHeld():Void
	{
		var window = open();
		if (window == null) return;

		var held = [];
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier)
		{
			held.push([modifier.shiftKey, modifier.ctrlKey, modifier.altKey, modifier.metaKey, modifier.numLock, modifier.capsLock].join(","));
		});

		key(KEY_DOWN, window.id, KeyCode.A, KeyModifier.RIGHT_SHIFT | KeyModifier.LEFT_META | KeyModifier.CAPS_LOCK);
		key(KEY_DOWN, window.id, KeyCode.A, KeyModifier.LEFT_CTRL | KeyModifier.RIGHT_ALT | KeyModifier.NUM_LOCK);

		Assert.equals("true,false,false,true,false,true|false,true,true,false,true,false", held.join("|"));
	}

	public function testKeyEventsCarryTheTimeOfTheKey():Void
	{
		var window = open();
		if (window == null) return;

		var times = [];
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) times.push(window.onKeyDown.timestamp));
		window.onKeyUp.add(function(keyCode:KeyCode, modifier:KeyModifier) times.push(window.onKeyUp.timestamp));

		key(KEY_DOWN, window.id, KeyCode.A, KeyModifier.NONE, 1234);
		key(KEY_UP, window.id, KeyCode.A, KeyModifier.NONE, 1300);

		Assert.equals("1234,1300", times.join(","));

		// The time can still be read once the listeners have returned
		Assert.equals(1234, window.onKeyDown.timestamp);
		Assert.equals(1300, window.onKeyUp.timestamp);
	}

	public function testAKeyReachesOnlyTheWindowItNames():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) heard.push("down in window"));
		window.onKeyUp.add(function(keyCode:KeyCode, modifier:KeyModifier) heard.push("up in window"));
		other.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) heard.push("down in other"));
		other.onKeyUp.add(function(keyCode:KeyCode, modifier:KeyModifier) heard.push("up in other"));

		key(KEY_DOWN, other.id, KeyCode.A, KeyModifier.NONE);
		key(KEY_UP, other.id, KeyCode.A, KeyModifier.NONE);

		Assert.equals("down in other,up in other", heard.join(","));
	}

	public function testAKeyForNoOpenWindowIsIgnored():Void
	{
		var window = open();
		if (window == null) return;

		var heard = 0;
		for (opened in [window, other])
		{
			opened.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) heard++);
			opened.onKeyUp.add(function(keyCode:KeyCode, modifier:KeyModifier) heard++);
		}

		// SDL names window 0 when no window has the keyboard
		for (windowID in [0, NO_WINDOW])
		{
			key(KEY_DOWN, windowID, KeyCode.A, KeyModifier.NONE);
			key(KEY_UP, windowID, KeyCode.A, KeyModifier.NONE);
		}

		Assert.equals(0, heard);
	}

	public function testAOnceListenerHearsOneKeyPress():Void
	{
		var window = open();
		if (window == null) return;

		var heard:Array<Int> = [];
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) heard.push(keyCode), true);

		key(KEY_DOWN, window.id, KeyCode.A, KeyModifier.NONE);
		key(KEY_DOWN, window.id, KeyCode.B, KeyModifier.NONE);

		Assert.equals("97", heard.join(","));
	}

	public function testListenersHearAKeyInOrderOfPriorityUntilItIsCanceled():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) heard.push("low"), false, -1);
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier)
		{
			heard.push("middle");
			if (keyCode == KeyCode.ESCAPE) window.onKeyDown.cancel();
		});
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) heard.push("high"), false, 1);

		key(KEY_DOWN, window.id, KeyCode.A, KeyModifier.NONE);
		key(KEY_DOWN, window.id, KeyCode.ESCAPE, KeyModifier.NONE);

		Assert.equals("high,middle,low,high,middle", heard.join(","));
	}

	public function testTheFullscreenShortcutTogglesFullscreen():Void
	{
		var window = open();
		if (window == null) return;

		var states = [], presses = 0;
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) presses++);

		shortcut(window, shortcutModifier(false));
		states.push(window.fullscreen);
		shortcut(window, shortcutModifier(false));
		states.push(window.fullscreen);

		Assert.equals("true,false", states.join(","));
		Assert.equals(2, presses, "the shortcut was not also dispatched as a key press");
	}

	public function testTheFullscreenShortcutWorksWithTheModifiersOfEitherSide():Void
	{
		var window = open();
		if (window == null) return;

		shortcut(window, shortcutModifier(true));

		Assert.isTrue(window.fullscreen);
	}

	public function testTheFullscreenShortcutWorksWithTheLocksOn():Void
	{
		var window = open();
		if (window == null) return;

		shortcut(window, shortcutModifier(false) | KeyModifier.NUM_LOCK | KeyModifier.CAPS_LOCK);

		Assert.isTrue(window.fullscreen);
	}

	public function testACanceledFullscreenShortcutDoesNotToggleFullscreen():Void
	{
		var window = open();
		if (window == null) return;

		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) window.onKeyDown.cancel());

		shortcut(window, shortcutModifier(false));

		Assert.isFalse(window.fullscreen, "a canceled key press still made the window fullscreen");
	}

	public function testACanceledFullscreenShortcutDoesNotLeaveFullscreen():Void
	{
		var window = open();
		if (window == null) return;

		shortcut(window, shortcutModifier(false));
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) window.onKeyDown.cancel());
		shortcut(window, shortcutModifier(false));

		Assert.isTrue(window.fullscreen, "a canceled key press still took the window out of fullscreen");
	}

	public function testTheFullscreenShortcutHeldDownTogglesOnce():Void
	{
		var window = open();
		if (window == null) return;

		// A key that is held repeats its press, and is released once
		for (repeat in 0...3)
		{
			key(KEY_DOWN, window.id, shortcutKey(), shortcutModifier(false));
		}

		var held = window.fullscreen;
		key(KEY_UP, window.id, shortcutKey(), shortcutModifier(false));

		Assert.isTrue(held, "the shortcut held down left the window out of fullscreen");
		Assert.isTrue(window.fullscreen, "releasing the shortcut changed fullscreen");
	}

	public function testTheShortcutsKeyWithOtherModifiersIsNotTheShortcut():Void
	{
		var window = open();
		if (window == null) return;

		var toggled = [];
		var modifiers:Array<KeyModifier> = [
			KeyModifier.NONE,
			KeyModifier.LEFT_SHIFT,
			shortcutModifier(false) | KeyModifier.RIGHT_SHIFT,
			#if mac
			KeyModifier.LEFT_CTRL, KeyModifier.LEFT_META, shortcutModifier(false) | KeyModifier.LEFT_ALT
			#else
			shortcutModifier(false) | KeyModifier.LEFT_CTRL, shortcutModifier(false) | KeyModifier.RIGHT_META
			#end
		];

		for (modifier in modifiers)
		{
			shortcut(window, modifier);
			if (window.fullscreen) toggled.push(bits(modifier));
		}

		Assert.equals("", toggled.join(","), "modifiers that toggled fullscreen: " + toggled.join(","));
	}

	public function testAMenuKeyEquivalentSelectsItsItemInsteadOfAKeyPress():Void
	{
		var window = open();
		if (window == null) return;

		if (!Window.supportsMenu)
		{
			// Only windows with a menu bar of their own have its key equivalents
			Assert.pass();
			return;
		}

		var menu = new Menu();
		var file = new Menu();
		menu.addSubmenu("File", file);
		var save = file.add(new MenuItem("Save"));
		save.keyCode = KeyCode.S;
		save.keyModifier = KeyModifier.CTRL;
		window.menu = menu;

		var heard = [];
		save.onSelect.add(function() heard.push("select"));
		window.onKeyDown.add(function(keyCode:KeyCode, modifier:KeyModifier) heard.push("down " + bits(modifier)));
		window.onKeyUp.add(function(keyCode:KeyCode, modifier:KeyModifier) heard.push("up " + bits(modifier)));

		key(KEY_DOWN, window.id, KeyCode.S, KeyModifier.LEFT_CTRL);
		key(KEY_UP, window.id, KeyCode.S, KeyModifier.LEFT_CTRL);
		key(KEY_DOWN, window.id, KeyCode.S, KeyModifier.NONE);

		Assert.equals("select,up 64,down 0", heard.join(","));
	}

	public function testAMousePressReachesItsWindowWithItsPositionAndButton():Void
	{
		var window = open();
		if (window == null) return;

		var presses = [], releases = 0;
		window.onMouseDown.add(function(x:Float, y:Float, button:MouseButton) presses.push(x + "," + y + "," + button));
		window.onMouseUp.add(function(x:Float, y:Float, button:Int) releases++);

		mouse(MOUSE_DOWN, window.id, 12.5, 34.25, MouseButton.RIGHT, 0, 0, 1);

		Assert.equals("12.5,34.25,2", presses.join("|"));
		Assert.equals(0, releases);
	}

	public function testAMouseReleaseReachesItsWindowWithItsPositionAndButton():Void
	{
		var window = open();
		if (window == null) return;

		var releases = [], presses = 0;
		window.onMouseUp.add(function(x:Float, y:Float, button:Int) releases.push(x + "," + y + "," + button));
		window.onMouseDown.add(function(x:Float, y:Float, button:MouseButton) presses++);

		mouse(MOUSE_UP, window.id, 56.75, 7.5, MouseButton.MIDDLE, 0, 0, 1);

		Assert.equals("56.75,7.5,1", releases.join("|"));
		Assert.equals(0, presses);
	}

	public function testEachMouseButtonIsItself():Void
	{
		var window = open();
		if (window == null) return;

		var buttons = [];
		window.onMouseDown.add(function(x:Float, y:Float, button:MouseButton)
		{
			buttons.push(button == MouseButton.LEFT ? "left" : (button == MouseButton.MIDDLE ? "middle" : (button == MouseButton.RIGHT ? "right" : "other")));
		});

		// SDL counts the buttons from 1, and Lime from 0
		for (button in 0...3)
		{
			mouse(MOUSE_DOWN, window.id, 0, 0, button, 0, 0, 1);
		}

		Assert.equals("left,middle,right", buttons.join(","));
	}

	public function testAMouseButtonKnowsWhichClickItIs():Void
	{
		var window = open();
		if (window == null) return;

		// OpenFL reads the count to tell a double click
		var counts = [];
		window.onMouseDown.add(function(x:Float, y:Float, button:MouseButton) counts.push("down " + @:privateAccess window.clickCount));
		window.onMouseUp.add(function(x:Float, y:Float, button:Int) counts.push("up " + @:privateAccess window.clickCount));

		for (click in 1...3)
		{
			mouse(MOUSE_DOWN, window.id, 1, 2, MouseButton.LEFT, 0, 0, click);
			mouse(MOUSE_UP, window.id, 1, 2, MouseButton.LEFT, 0, 0, click);
		}

		Assert.equals("down 1,up 1,down 2,up 2", counts.join(","));

		// The count is of the press or release being dispatched
		Assert.equals(0, @:privateAccess window.clickCount);
	}

	public function testAMouseMoveGivesWhereItIsAndHowFarItMoved():Void
	{
		var window = open();
		if (window == null) return;

		var moves = [];
		window.onMouseMove.add(function(x:Float, y:Float) moves.push("at " + x + "," + y));
		window.onMouseMoveRelative.add(function(x:Float, y:Float) moves.push("by " + x + "," + y));

		mouse(MOUSE_MOVE, window.id, 100.5, 50.25, 0, -3, 7, 0);

		Assert.equals("at 100.5,50.25|by -3,7", moves.join("|"));
	}

	public function testTheMouseWheelGivesItsStepsAcrossAndDown():Void
	{
		var window = open();
		if (window == null) return;

		var scrolls = [];
		window.onMouseWheel.add(function(deltaX:Float, deltaY:Float, mode) scrolls.push(deltaX + "," + deltaY));

		// Whole steps, then the fractions of a step SDL also gives
		mouse(MOUSE_WHEEL, window.id, 2, -3, 0, 0.5, -0.75, 0);
		window.preciseMouseWheel = true;
		mouse(MOUSE_WHEEL, window.id, 2, -3, 0, 0.5, -0.75, 0);

		Assert.equals("2,-3|0.5,-0.75", scrolls.join("|"));
	}

	public function testMouseEventsCarryTheTimeOfTheInput():Void
	{
		var window = open();
		if (window == null) return;

		var times = [];
		window.onMouseDown.add(function(x:Float, y:Float, button:MouseButton) times.push("down " + window.onMouseDown.timestamp));
		window.onMouseUp.add(function(x:Float, y:Float, button:Int) times.push("up " + window.onMouseUp.timestamp));
		window.onMouseMove.add(function(x:Float, y:Float) times.push("move " + window.onMouseMove.timestamp));
		window.onMouseMoveRelative.add(function(x:Float, y:Float) times.push("move by " + window.onMouseMoveRelative.timestamp));
		window.onMouseWheel.add(function(deltaX:Float, deltaY:Float, mode) times.push("wheel " + window.onMouseWheel.timestamp));

		mouse(MOUSE_DOWN, window.id, 1, 2, MouseButton.LEFT, 0, 0, 1, 1234);
		mouse(MOUSE_MOVE, window.id, 3, 4, 0, 2, 2, 0, 1250);
		mouse(MOUSE_UP, window.id, 3, 4, MouseButton.LEFT, 0, 0, 1, 1300);
		mouse(MOUSE_WHEEL, window.id, 0, 1, 0, 0, 0.5, 0, 1400);
		window.preciseMouseWheel = true;
		mouse(MOUSE_WHEEL, window.id, 0, 1, 0, 0, 0.5, 0, 1450);

		Assert.equals("down 1234|move 1250|move by 1250|up 1300|wheel 1400|wheel 1450", times.join("|"));

		// The time can still be read once the listeners have returned
		Assert.equals(1234, window.onMouseDown.timestamp);
		Assert.equals(1250, window.onMouseMove.timestamp);
		Assert.equals(1300, window.onMouseUp.timestamp);
	}

	public function testTouchEventsCarryTheTimeOfTheInput():Void
	{
		var times = [];
		listenToTouch(Touch.onStart, function(touch:Touch) times.push("start " + Touch.onStart.timestamp));
		listenToTouch(Touch.onMove, function(touch:Touch) times.push("move " + Touch.onMove.timestamp));
		listenToTouch(Touch.onEnd, function(touch:Touch) times.push("end " + Touch.onEnd.timestamp));

		touch(TOUCH_START, 0.25, 0.5, 7, 2000);
		touch(TOUCH_MOVE, 0.3, 0.5, 7, 2016);
		touch(TOUCH_END, 0.3, 0.5, 7, 2040);

		Assert.equals("start 2000|move 2016|end 2040", times.join("|"));
		Assert.equals(2000, Touch.onStart.timestamp);
	}

	#if windows
	/**
		Mouse messages are posted to the window while the application waits, so
		SDL takes them in together. The first move holds up the rest, so they
		are dispatched well after SDL took them, and the times must be SDL's.
	**/
	@:timeout(20000)
	public function testRealMouseEventsCarryTheTimeSDLTookThem(async:Async):Void
	{
		var window = open();
		if (window == null)
		{
			async.done();
			return;
		}

		var heard = [];
		var times = [];
		var dispatched = [];

		window.onMouseMove.add(function(x:Float, y:Float)
		{
			heard.push("move " + x + "," + y);
			times.push(window.onMouseMove.timestamp);
			dispatched.push(System.getTimer());
			if (heard.length == 1) Sys.sleep(0.1);
		});
		window.onMouseDown.add(function(x:Float, y:Float, button:MouseButton)
		{
			heard.push("down " + x + "," + y);
			times.push(window.onMouseDown.timestamp);
			dispatched.push(System.getTimer());
		});
		window.onMouseUp.add(function(x:Float, y:Float, button:Int)
		{
			heard.push("up " + x + "," + y);
			times.push(window.onMouseUp.timestamp);
			dispatched.push(System.getTimer());
		});

		var before = System.getTimer();

		if (!postMouseMessages(window))
		{
			Assert.fail("the mouse messages could not be posted");
			async.done();
			return;
		}

		Timer.delay(function()
		{
			// The real cursor is not over the window, so SDL may also move to its
			// edge when Windows says the mouse has left
			Assert.equals("move 10,20|move 30,40|down 30,40|up 30,40", heard.slice(0, 4).join("|"));

			if (times.length >= 4)
			{
				for (i in 0...4)
				{
					// Compared by the time between them, which stays right where the timer wraps
					Assert.isTrue(timeBetween(before, times[i]) >= 0 && timeBetween(times[i], dispatched[i]) >= 0,
						heard[i] + " was timed " + times[i] + ", posted from " + before + " and dispatched at " + dispatched[i]);
				}

				// Dispatch times would be 100 ms or more after the first move
				Assert.isTrue(timeBetween(times[0], times[3]) < 50, "the times were " + times.join(", ") + " and the dispatches " + dispatched.join(", "));
			}

			async.done();
		}, 1000);
	}

	// The milliseconds from one System.getTimer() reading to a later one, as an
	// Int32 difference, which stays right where the timer wraps past 2^31
	private static function timeBetween(earlier:Int, later:Int):Int
	{
		return (later : haxe.Int32) - (earlier : haxe.Int32);
	}

	/**
		Posts two moves and a click of the left button to the window, through
		PowerShell, and returns once they are in its message queue.
	**/
	private static function postMouseMessages(window:Window):Bool
	{
		var hwnd = Int64.toStr(window.nativeHandle.window);
		var post = "[LimeTest.User32]::PostMessage($h, ";
		var script = "Add-Type -Namespace LimeTest -Name User32 -MemberDefinition '[DllImport(\"user32.dll\")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);'\n"
			+ "$h = [IntPtr][Int64]" + hwnd + "\n"
			// WM_MOUSEMOVE, WM_MOUSEMOVE, WM_LBUTTONDOWN, WM_LBUTTONUP, each with y in the high word of lParam
			+ "$ok = " + post + "0x0200, [IntPtr]0, [IntPtr](10 + (20 -shl 16)))\n"
			+ "$ok = " + post + "0x0200, [IntPtr]0, [IntPtr](30 + (40 -shl 16))) -and $ok\n"
			+ "$ok = " + post + "0x0201, [IntPtr]1, [IntPtr](30 + (40 -shl 16))) -and $ok\n"
			+ "$ok = " + post + "0x0202, [IntPtr]0, [IntPtr](30 + (40 -shl 16))) -and $ok\n"
			+ "if (-not $ok) { exit 1 }\n";

		// An encoded command is UTF-16, and needs no quoting
		var utf16 = Bytes.alloc(script.length * 2);
		for (i in 0...script.length)
		{
			utf16.setUInt16(i * 2, StringTools.fastCodeAt(script, i));
		}

		var process = new sys.io.Process(powerShell(), ["-NoProfile", "-NonInteractive", "-EncodedCommand", Base64.encode(utf16)]);
		var exitCode = process.exitCode();
		process.close();
		return exitCode == 0;
	}

	private static function powerShell():String
	{
		// HashLink starts a process by its path, without looking through PATH
		var root = Sys.getEnv("SystemRoot");
		var path = root != null ? root + "\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" : null;
		return path != null && sys.FileSystem.exists(path) ? path : "powershell";
	}
	#end

	public function testTheMouseReachesOnlyTheWindowItNames():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		listenToMouse(window, "window", heard);
		listenToMouse(other, "other", heard);

		for (type in [MOUSE_DOWN, MOUSE_UP, MOUSE_MOVE, MOUSE_WHEEL])
		{
			mouse(type, other.id, 1, 2, MouseButton.LEFT, 3, 4, 1);
		}

		Assert.equals("other down,other up,other move,other move by,other wheel", heard.join(","));
	}

	public function testTheMouseOverNoOpenWindowIsIgnored():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		listenToMouse(window, "window", heard);
		listenToMouse(other, "other", heard);

		for (windowID in [0, NO_WINDOW])
		{
			for (type in [MOUSE_DOWN, MOUSE_UP, MOUSE_MOVE, MOUSE_WHEEL])
			{
				mouse(type, windowID, 1, 2, MouseButton.LEFT, 3, 4, 1);
			}
		}

		Assert.equals("", heard.join(","));
	}

	public function testACopyOfAMouseEventNamesTheSameWindow():Void
	{
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.mouseEventInfo;
		info.type = cast MOUSE_MOVE;
		info.windowID = 7;
		info.x = 1;
		info.y = 2;
		info.button = 2;
		info.movementX = 3;
		info.movementY = 4;
		info.clickCount = 5;

		var copy = info.clone();

		Assert.equals(7, copy.windowID);
		Assert.equals("1,2,2,3,4,5", [copy.x, copy.y, copy.button, copy.movementX, copy.movementY, copy.clickCount].join(","));
	}

	public function testTypedTextReachesItsWindow():Void
	{
		var window = open();
		if (window == null) return;

		var typed = [], edits = 0;
		window.onTextInput.add(function(text:String) typed.push(text));
		window.onTextEdit.add(function(text:String, start:Int, length:Int) edits++);

		text(TEXT_INPUT, window.id, "a", 0, 0);
		text(TEXT_INPUT, window.id, "Lime 8.4", 0, 0);

		Assert.equals("a|Lime 8.4", typed.join("|"));
		Assert.equals(0, edits);
	}

	public function testTypedTextKeepsCharactersOfSeveralBytes():Void
	{
		var window = open();
		if (window == null) return;

		// Characters of two, three and four bytes in UTF-8
		var characters = "\u00E9\u6F22\u{1F600}";
		var typed = [];
		window.onTextInput.add(function(text:String) typed.push(text));

		text(TEXT_INPUT, window.id, characters, 0, 0);

		Assert.equals(1, typed.length);
		Assert.equals(characters, typed[0]);
	}

	public function testTextBeingComposedGivesItsTextAndSelection():Void
	{
		var window = open();
		if (window == null) return;

		var composed = "\u304B\u306A";
		var edits = [], typed = 0;
		window.onTextEdit.add(function(text:String, start:Int, length:Int) edits.push(text + "," + start + "," + length));
		window.onTextInput.add(function(text:String) typed++);

		text(TEXT_EDIT, window.id, composed, 3, 2);

		Assert.equals(composed + ",3,2", edits.join("|"));
		Assert.equals(0, typed);
	}

	public function testTextReachesOnlyTheWindowItNames():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		window.onTextInput.add(function(text:String) heard.push("typed in window"));
		window.onTextEdit.add(function(text:String, start:Int, length:Int) heard.push("composed in window"));
		other.onTextInput.add(function(text:String) heard.push("typed in other"));
		other.onTextEdit.add(function(text:String, start:Int, length:Int) heard.push("composed in other"));

		text(TEXT_EDIT, other.id, "a", 0, 1);
		text(TEXT_INPUT, other.id, "a", 0, 0);

		for (windowID in [0, NO_WINDOW])
		{
			text(TEXT_EDIT, windowID, "a", 0, 1);
			text(TEXT_INPUT, windowID, "a", 0, 0);
		}

		Assert.equals("composed in other,typed in other", heard.join(","));
	}

	public function testADroppedFileGivesItsPath():Void
	{
		var window = open();
		if (window == null) return;

		var path = "C:\\Dropped files\\caf\u00E9 \u6F22.txt";
		var dropped = [];
		window.onDropFile.add(function(file:String) dropped.push(file));

		drop(path, window);

		Assert.equals(1, dropped.length);
		Assert.equals(path, dropped[0]);
	}

	public function testADroppedFileIsReportedByTheWindowItWasDroppedOn():Void
	{
		var window = open();
		if (window == null) return;

		var dropped = [];
		window.onDropFile.add(function(file:String) dropped.push("window"));
		other.onDropFile.add(function(file:String) dropped.push("other"));

		drop("file.txt", other);

		Assert.equals("other", dropped.join(","));
	}

	private function open():Window
	{
		if (window == null)
		{
			// The application listens to the first window it is given, and these
			// tests remove every listener of theirs
			if (Application.current.window == null) create();

			window = create();
			other = create();
		}

		if (window == null || other == null)
		{
			// Without a display, as on the Linux runners, no window can be created.
			// utest takes a warning as a failure, so the test passes, saying why
			if (!reported) trace("No window can be created here, so input events were not tested");
			reported = true;
			Assert.pass();
			return null;
		}

		return window;
	}

	private static function create():Window
	{
		// The windows are left open, hidden, as closing the last window of the
		// application ends it
		return Application.current.createWindow({
			width: 64,
			height: 64,
			hidden: true,
			title: "InputEventTest"
		});
	}

	private static function code(keyCode:KeyCode):Int
	{
		return keyCode;
	}

	private static function bits(modifier:KeyModifier):Int
	{
		return modifier;
	}

	private static function shortcutKey():KeyCode
	{
		return #if mac KeyCode.F #else KeyCode.RETURN #end;
	}

	private static function shortcutModifier(right:Bool):KeyModifier
	{
		#if mac
		return right ? KeyModifier.RIGHT_CTRL | KeyModifier.RIGHT_META : KeyModifier.LEFT_CTRL | KeyModifier.LEFT_META;
		#else
		return right ? KeyModifier.RIGHT_ALT : KeyModifier.LEFT_ALT;
		#end
	}

	private static function shortcut(window:Window, modifier:KeyModifier):Void
	{
		key(KEY_DOWN, window.id, shortcutKey(), modifier);
		key(KEY_UP, window.id, shortcutKey(), modifier);
	}

	private static function listenToMouse(window:Window, name:String, heard:Array<String>):Void
	{
		window.onMouseDown.add(function(x:Float, y:Float, button:MouseButton) heard.push(name + " down"));
		window.onMouseUp.add(function(x:Float, y:Float, button:Int) heard.push(name + " up"));
		window.onMouseMove.add(function(x:Float, y:Float) heard.push(name + " move"));
		window.onMouseMoveRelative.add(function(x:Float, y:Float) heard.push(name + " move by"));
		window.onMouseWheel.add(function(deltaX:Float, deltaY:Float, mode) heard.push(name + " wheel"));
	}

	private static function key(type:Int, windowID:Int, keyCode:KeyCode, modifier:KeyModifier, timestamp:Int = 0):Void
	{
		// The event as native code fills it in, then the handler it calls
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.keyEventInfo;
		info.type = cast type;
		info.windowID = windowID;
		info.keyCode = code(keyCode);
		info.modifier = modifier;
		info.timestamp = timestamp;
		@:privateAccess backend.handleKeyEvent();
	}

	private static function mouse(type:Int, windowID:Int, x:Float, y:Float, button:Int, movementX:Float, movementY:Float, clickCount:Int,
			timestamp:Int = 0):Void
	{
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.mouseEventInfo;
		info.type = cast type;
		info.windowID = windowID;
		info.x = x;
		info.y = y;
		info.button = button;
		info.movementX = movementX;
		info.movementY = movementY;
		info.clickCount = clickCount;
		info.timestamp = timestamp;
		@:privateAccess backend.handleMouseEvent();
	}

	private function listenToTouch(event:Event<Touch->Void>, listener:Touch->Void):Void
	{
		event.add(listener);
		touchListeners.push(listener);
	}

	private static function touch(type:Int, x:Float, y:Float, id:Int, timestamp:Int):Void
	{
		// Touch events name no window
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.touchEventInfo;
		info.type = cast type;
		info.x = x;
		info.y = y;
		info.id = id;
		info.dx = 0;
		info.dy = 0;
		info.pressure = 1;
		info.device = 0;
		info.timestamp = timestamp;
		@:privateAccess backend.handleTouchEvent();
	}

	private static function text(type:Int, windowID:Int, text:String, start:Int, length:Int):Void
	{
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.textEventInfo;
		info.type = cast type;
		info.windowID = windowID;
		// HashLink is handed the text as UTF-8 bytes
		info.text = #if hl @:privateAccess text.toUtf8() #else text #end;
		info.start = start;
		info.length = length;
		@:privateAccess backend.handleTextEvent();
	}

	private static function drop(file:String, window:Window):Void
	{
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.dropEventInfo;
		info.type = cast 0;
		info.file = #if hl @:privateAccess file.toUtf8() #else file #end;
		// SDL says which window the file was dropped on
		info.windowID = window.id;

		@:privateAccess backend.handleDropEvent();
	}
	#end
}
