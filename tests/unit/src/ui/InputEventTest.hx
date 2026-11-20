package ui;

import lime.app.Application;
import lime.system.System;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Menu;
import lime.ui.MenuItem;
import lime.ui.MouseButton;
import lime.ui.Window;
import utest.Assert;
import utest.Test;

/**
	Key, mouse, text and drop events are handed to the application as its event
	loop would, and are expected at the listeners of the window they name, with
	what SDL reports for them: the key code and SDL_Keymod bits of a key, the
	position, button and click count of a mouse button, the position and the
	relative motion of a mouse move, the steps of a wheel, the text typed or
	being composed, and the path of a dropped file or the text dropped, between
	the start and the end of the drop.

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
	private static inline var TEXT_INPUT = 0;
	private static inline var TEXT_EDIT = 1;
	private static inline var DROP_FILE = 0;
	private static inline var DROP_TEXT = 1;
	private static inline var DROP_BEGIN = 2;
	private static inline var DROP_COMPLETE = 3;

	// SDL numbers windows from 1 as they are created
	private static inline var NO_WINDOW = 0x3FFFFF;

	private var window:Window;
	private var other:Window;
	private var reported:Bool = false;

	public function teardown():Void
	{
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
			opened.onDropStart.removeAll();
			opened.onDropText.removeAll();
			opened.onDropEnd.removeAll();
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

	public function testMouseEventsCarryTheTimeTheyWereDispatched():Void
	{
		var window = open();
		if (window == null) return;

		var time = -1;
		window.onMouseDown.add(function(x:Float, y:Float, button:MouseButton) time = window.onMouseDown.timestamp);

		var before = System.getTimer();
		mouse(MOUSE_DOWN, window.id, 0, 0, MouseButton.LEFT, 0, 0, 1);
		var after = System.getTimer();

		Assert.isTrue(time >= before && time <= after, "a press dispatched from " + before + " to " + after + " was timed " + time);
	}

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

	public function testFilesDroppedTogetherComeBetweenTheStartAndTheEnd():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		listenToDrops(window, "window", heard);

		dropEvent(DROP_BEGIN, null, window.id);
		dropEvent(DROP_FILE, "one.txt", window.id);
		dropEvent(DROP_FILE, "two.txt", window.id);
		dropEvent(DROP_COMPLETE, null, window.id);

		Assert.equals("window start|window file one.txt|window file two.txt|window end", heard.join("|"));
	}

	public function testDroppedTextIsNotAFile():Void
	{
		var window = open();
		if (window == null) return;

		var text = "Dropped caf\u00E9 \u6F22\non two lines";
		var heard = [];
		listenToDrops(window, "window", heard);

		dropEvent(DROP_BEGIN, null, window.id);
		dropEvent(DROP_TEXT, text, window.id);
		dropEvent(DROP_COMPLETE, null, window.id);

		Assert.equals("window start|window text " + text + "|window end", heard.join("|"));
	}

	public function testADropOnNoKnownWindowReachesEveryWindow():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		listenToDrops(window, "window", heard);
		listenToDrops(other, "other", heard);

		// As for a file dropped on the application's icon
		dropEvent(DROP_BEGIN, null, 0);
		dropEvent(DROP_TEXT, "text", 0);
		dropEvent(DROP_COMPLETE, null, 0);

		for (name in ["window", "other"])
		{
			var own = [for (line in heard) if (StringTools.startsWith(line, name + " ")) line];
			Assert.equals(name + " start|" + name + " text text|" + name + " end", own.join("|"));
		}
	}

	#if (cpp && windows)
	/**
		Sends the window the message Explorer sends when two files are dropped
		on it, which SDL reads into a drop of two files.
	**/
	@:timeout(10000)
	public function testRealFilesDroppedTogetherComeAsAGroup(async:utest.Async):Void
	{
		var window = open();

		if (window == null)
		{
			async.done();
			return;
		}

		var heard = [];
		listenToDrops(window, "window", heard);
		WindowsDrop.dropFiles(window.nativeHandle.window, ["C:/Dropped/one.txt", "C:/Dropped/caf\u00E9.txt"]);

		haxe.Timer.delay(function()
		{
			Assert.equals("window start|window file C:/Dropped/one.txt|window file C:/Dropped/caf\u00E9.txt|window end", heard.join("|"));
			async.done();
		}, 500);
	}
	#end

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

	private static function mouse(type:Int, windowID:Int, x:Float, y:Float, button:Int, movementX:Float, movementY:Float, clickCount:Int):Void
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
		@:privateAccess backend.handleMouseEvent();
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

	private static function listenToDrops(window:Window, name:String, heard:Array<String>):Void
	{
		window.onDropStart.add(function() heard.push(name + " start"));
		window.onDropFile.add(function(file:String) heard.push(name + " file " + file));
		window.onDropText.add(function(text:String) heard.push(name + " text " + text));
		window.onDropEnd.add(function() heard.push(name + " end"));
	}

	private static function dropEvent(type:Int, text:String, windowID:Int):Void
	{
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.dropEventInfo;
		info.type = cast type;
		// The start and the end carry no text, which native code passes as empty
		if (text == null) text = "";
		info.file = #if hl @:privateAccess text.toUtf8() #else text #end;
		info.windowID = windowID;

		@:privateAccess backend.handleDropEvent();
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

	#if (js && html5)
	@:timeout(10000)
	public function testTextAndFilesDroppedOnThePageComeBetweenTheStartAndTheEnd(async:utest.Async):Void
	{
		// The tests start before the application has opened its window
		var timer = new haxe.Timer(10);
		var started = false;
		timer.run = function()
		{
			var window = Application.current.window;
			// A run already queued can come after stop()
			if (started || window == null) return;
			started = true;
			timer.stop();

			var heard = [];
			window.onDropStart.add(function() heard.push("start"));
			window.onDropFile.add(function(file) heard.push("file"));
			window.onDropText.add(function(text) heard.push("text " + text));
			window.onDropEnd.add(function() heard.push("end"));

			var backend = @:privateAccess window.__backend;
			var element:js.html.Element = backend.canvas != null ? cast backend.canvas : cast backend.div;

			var text = new js.html.DataTransfer();
			text.setData("text/plain", "Dropped text");
			var textDropped = element.dispatchEvent(new js.html.DragEvent("drop", {dataTransfer: text, bubbles: true, cancelable: true}));

			var files = new js.html.DataTransfer();
			files.items.add(new js.html.File(["one"], "one.txt"));
			files.items.add(new js.html.File(["two"], "two.txt"));
			element.dispatchEvent(new js.html.DragEvent("drop", {dataTransfer: files, bubbles: true, cancelable: true}));

			// Nothing to take is not a drop
			element.dispatchEvent(new js.html.DragEvent("drop", {dataTransfer: new js.html.DataTransfer(), bubbles: true, cancelable: true}));

			window.onDropStart.removeAll();
			window.onDropFile.removeAll();
			window.onDropText.removeAll();
			window.onDropEnd.removeAll();

			// The files come as the page's FileList, in one dispatch
			Assert.equals("start|text Dropped text|end|start|file|end", heard.join("|"));
			Assert.isFalse(textDropped, "the browser's own handling of the drop was not prevented");
			async.done();
		};
	}
	#end
}

#if (cpp && windows && lime_cffi && !macro)
@:cppFileCode('#include <windows.h>
#include <shlobj.h>
#include <string>')
private class WindowsDrop
{
	/**
		Sends `hwnd` a WM_DROPFILES message for `files`, as Explorer does.
	**/
	public static function dropFiles(hwnd:haxe.Int64, files:Array<String>):Void
	{
		var low = haxe.Int64.getLow(hwnd);
		var high = haxe.Int64.getHigh(hwnd);

		// The paths, each ending in a null character, and a null character after the last
		untyped __cpp__('
			std::wstring list;
			for (int i = 0; i < {0}->length; i++) {
				const char* utf8 = {0}->__get(i).utf8_str();
				int count = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, NULL, 0);
				std::wstring file(count, 0);
				MultiByteToWideChar(CP_UTF8, 0, utf8, -1, &file[0], count);
				list.append(file.c_str(), count);
			}
			list.push_back(0);
			HGLOBAL memory = GlobalAlloc(GHND, sizeof(DROPFILES) + list.size() * sizeof(wchar_t));
			DROPFILES* drop = (DROPFILES*)GlobalLock(memory);
			drop->pFiles = sizeof(DROPFILES);
			drop->fWide = TRUE;
			memcpy((char*)drop + sizeof(DROPFILES), list.data(), list.size() * sizeof(wchar_t));
			GlobalUnlock(memory);
			::SendMessageW((HWND)(((unsigned long long)(unsigned int){2} << 32) | (unsigned int){1}), WM_DROPFILES, (WPARAM)memory, 0)', files, low, high);
	}
}
#end
