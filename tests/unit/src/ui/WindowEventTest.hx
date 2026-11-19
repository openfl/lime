package ui;

import haxe.Timer;
import lime.app.Application;
import lime.media.AudioManager;
import lime.system.System;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Window;
import utest.Assert;
import utest.Test;

/**
	Window events are handed to the application as its event loop would, and are
	expected at the listeners of the window they name. The window is expected to
	say what SDL says of a window after each: where it was moved to, the size it
	was given, minimized or maximized until it is restored, and still fullscreen
	when it is minimized and restored, as the fullscreen flag of an SDL window
	is only changed by asking for it.

	`Application.onWindowFullscreen` is documented as called when a window
	enters fullscreen, and `Application.onWindowRestore` when it is restored
	from being minimized or fullscreen.
**/
class WindowEventTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && (windows || mac || linux) && !rpi)
	private static inline var ACTIVATE = 0;
	private static inline var CLOSE = 1;
	private static inline var DEACTIVATE = 2;
	private static inline var ENTER = 3;
	private static inline var EXPOSE = 4;
	private static inline var FOCUS_IN = 5;
	private static inline var FOCUS_OUT = 6;
	private static inline var LEAVE = 7;
	private static inline var MAXIMIZE = 8;
	private static inline var MINIMIZE = 9;
	private static inline var MOVE = 10;
	private static inline var RESIZE = 11;
	private static inline var RESTORE = 12;
	private static inline var SHOW = 13;
	private static inline var HIDE = 14;

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

			opened.onActivate.removeAll();
			opened.onDeactivate.removeAll();
			opened.onEnter.removeAll();
			opened.onExpose.removeAll();
			opened.onFocusIn.removeAll();
			opened.onFocusOut.removeAll();
			opened.onFullscreen.removeAll();
			opened.onLeave.removeAll();
			opened.onMaximize.removeAll();
			opened.onMinimize.removeAll();
			opened.onMove.removeAll();
			opened.onResize.removeAll();
			opened.onRestore.removeAll();
			opened.onShow.removeAll();
			opened.onHide.removeAll();
			opened.onDisplayScaleChange.removeAll();
			opened.onKeyDown.removeAll();

			if (opened.fullscreen) opened.fullscreen = false;

			// The window itself was never minimized or maximized
			event(RESTORE, opened.id);
		}
	}

	public function testEachWindowEventReachesItsOwnListeners():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		listen(window, "", heard);

		for (type in [DEACTIVATE, ACTIVATE, ENTER, EXPOSE, FOCUS_IN, FOCUS_OUT, LEAVE, MAXIMIZE, MINIMIZE, RESTORE, SHOW, HIDE])
		{
			event(type, window.id);
		}

		Assert.equals("deactivate,activate,enter,expose,focusIn,focusOut,leave,maximize,minimize,restore,show,hide", heard.join(","));
	}

	public function testAWindowEventReachesOnlyTheWindowItNames():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		listen(window, "window ", heard);
		listen(other, "other ", heard);

		event(FOCUS_IN, other.id);
		event(MOVE, other.id, other.x, other.y);
		event(RESIZE, other.id, 0, 0, other.width, other.height);
		event(FOCUS_OUT, other.id);

		Assert.equals("other focusIn,other move,other resize,other focusOut", heard.join(","));
	}

	public function testAWindowEventForNoOpenWindowIsIgnored():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		listen(window, "window ", heard);
		listen(other, "other ", heard);

		for (windowID in [0, NO_WINDOW])
		{
			for (type in [DEACTIVATE, ACTIVATE, CLOSE, ENTER, EXPOSE, FOCUS_IN, FOCUS_OUT, LEAVE, MAXIMIZE, MINIMIZE, MOVE, RESIZE, RESTORE, SHOW, HIDE])
			{
				event(type, windowID, 5, 6, 7, 8);
			}
		}

		Assert.equals("", heard.join(","));
		Assert.isFalse(AudioManager.__suspended, "audio was paused for a window that is not open");
	}

	public function testAMovedWindowGivesItsNewPosition():Void
	{
		var window = open();
		if (window == null) return;

		var left = window.x, top = window.y;
		var moves = [];
		window.onMove.add(function(x:Float, y:Float) moves.push(x + "," + y + " at " + window.x + "," + window.y));

		// A window on a display to the left of the main one
		event(MOVE, window.id, -120, 45);
		var moved = window.x + "," + window.y;
		event(MOVE, window.id, left, top);

		Assert.equals("-120,45", moved);
		Assert.equals("-120,45 at -120,45|" + left + "," + top + " at " + left + "," + top, moves.join("|"));
	}

	public function testAResizedWindowGivesItsNewSize():Void
	{
		var window = open();
		if (window == null) return;

		var wide = window.width, high = window.height;
		var sizes = [];
		window.onResize.add(function(width:Int, height:Int) sizes.push(width + "x" + height + " of " + window.width + "x" + window.height));

		event(RESIZE, window.id, 0, 0, 321, 123);
		var resized = window.width + "x" + window.height;
		event(RESIZE, window.id, 0, 0, wide, high);

		Assert.equals("321x123", resized);
		Assert.equals("321x123 of 321x123|" + wide + "x" + high + " of " + wide + "x" + high, sizes.join("|"));
	}

	public function testMovingAndResizingLeaveTheOtherAlone():Void
	{
		var window = open();
		if (window == null) return;

		var before = [window.x, window.y, window.width, window.height].join(",");
		var heard = [];
		listen(window, "", heard);

		// A move carries no size and a resize no position, whatever the event last held
		event(MOVE, window.id, window.x, window.y, 999, 888);
		event(RESIZE, window.id, 777, 666, window.width, window.height);

		Assert.equals(before, [window.x, window.y, window.width, window.height].join(","));
		Assert.equals("move,resize", heard.join(","));
	}

	public function testAWindowIsMinimizedUntilItIsRestored():Void
	{
		var window = open();
		if (window == null) return;

		var states = [];
		window.onMinimize.add(function() states.push("minimize " + state(window)));
		window.onRestore.add(function() states.push("restore " + state(window)));

		event(MINIMIZE, window.id);
		states.push(state(window));
		event(RESTORE, window.id);
		states.push(state(window));

		Assert.equals("minimize minimized,minimized,restore ,", states.join(","));
	}

	public function testAWindowIsMaximizedUntilItIsRestored():Void
	{
		var window = open();
		if (window == null) return;

		var states = [];
		window.onMaximize.add(function() states.push("maximize " + state(window)));
		window.onRestore.add(function() states.push("restore " + state(window)));

		event(MAXIMIZE, window.id);
		states.push(state(window));
		event(RESTORE, window.id);
		states.push(state(window));

		Assert.equals("maximize maximized,maximized,restore ,", states.join(","));
	}

	public function testAWindowIsEitherMinimizedOrMaximized():Void
	{
		var window = open();
		if (window == null) return;

		var states = [];

		// SDL clears each flag when it sets the other
		event(MAXIMIZE, window.id);
		event(MINIMIZE, window.id);
		states.push(state(window));
		event(MAXIMIZE, window.id);
		states.push(state(window));

		Assert.equals("minimized,maximized", states.join(","));
	}

	public function testOnlyTheWindowNamedChangesState():Void
	{
		var window = open();
		if (window == null) return;

		event(MINIMIZE, other.id);
		var states = state(window) + "|" + state(other);
		event(RESTORE, other.id);

		Assert.equals("|minimized", states);
	}

	@Ignored("Waiting on #873")
	public function testAFullscreenWindowIsStillFullscreenOnceMinimizedAndRestored():Void
	{
		var window = open();
		if (window == null) return;

		// As when the user switches to another application and back
		window.fullscreen = true;
		event(FOCUS_OUT, window.id);
		event(MINIMIZE, window.id);
		event(RESTORE, window.id);
		event(FOCUS_IN, window.id);

		Assert.isTrue(window.fullscreen, "a fullscreen window says it is not, once it was minimized and restored");
	}

	@Ignored("Waiting on #873")
	public function testTheFullscreenShortcutLeavesFullscreenOnceMinimizedAndRestored():Void
	{
		var window = open();
		if (window == null) return;

		var entered = 0;
		window.fullscreen = true;
		event(MINIMIZE, window.id);
		event(RESTORE, window.id);

		// The window is fullscreen, so the shortcut is to leave it, not to enter it again
		window.onFullscreen.add(function() entered++);
		shortcut(window);

		Assert.equals(0, entered, "the shortcut entered fullscreen in a window that was fullscreen");
	}

	public function testAWindowCreatedFullscreenSaysItIs():Void
	{
		if (open() == null) return;

		var fullscreen = Application.current.createWindow({
			width: 64,
			height: 64,
			hidden: true,
			fullscreen: true,
			title: "WindowEventTest"
		});

		Assert.notNull(fullscreen, "a fullscreen window could not be created");
		if (fullscreen == null) return;

		var said = fullscreen.fullscreen;
		fullscreen.close();

		Assert.isTrue(said, "a window created fullscreen says it is not");
	}

	public function testEnteringFullscreenIsDispatchedOnce():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		window.onFullscreen.add(function() heard.push("fullscreen " + window.fullscreen));

		window.fullscreen = true;
		var entered = heard.join(",");
		window.fullscreen = false;

		Assert.equals("fullscreen true", entered);
		Assert.equals("fullscreen true", heard.join(","), "leaving fullscreen was dispatched as entering it");
	}

	public function testAWindowThatIsFullscreenDoesNotEnterItAgain():Void
	{
		var window = open();
		if (window == null) return;

		var entered = 0;
		window.fullscreen = true;
		window.onFullscreen.add(function() entered++);
		window.fullscreen = true;

		Assert.equals(0, entered, "a window that was fullscreen entered fullscreen");
	}

	public function testLeavingFullscreenRestoresTheWindow():Void
	{
		var window = open();
		if (window == null) return;

		var restored = 0;
		window.fullscreen = true;
		window.onRestore.add(function() restored++);
		window.fullscreen = false;

		Assert.equals(1, restored, "a window restored from fullscreen dispatched onRestore " + restored + " times");
	}

	#if !lime_disable_window_scale_change
	public function testAChangeOfScaleIsDispatchedWithTheNewScale():Void
	{
		var window = open();
		if (window == null) return;

		var scale = window.scale;
		var changes = [];
		window.onDisplayScaleChange.add(function() changes.push(window.scale));

		// SDL reports a change of scale as a resize, so the scale of the display
		// the window is on is read then. Here, the window last had another
		@:privateAccess window.__scale = scale * 2;
		event(RESIZE, window.id, 0, 0, window.width, window.height);
		event(RESIZE, window.id, 0, 0, window.width, window.height);

		Assert.equals(1, changes.length);
		Assert.equals(scale, changes[0]);
		Assert.equals(scale, window.scale);
	}

	public function testAResizeAtTheSameScaleIsNoChangeOfScale():Void
	{
		var window = open();
		if (window == null) return;

		var changes = 0;
		window.onDisplayScaleChange.add(function() changes++);
		other.onDisplayScaleChange.add(function() changes++);

		event(RESIZE, window.id, 0, 0, window.width, window.height);

		Assert.equals(0, changes);
	}
	#end

	public function testAudioIsPausedWhileTheWindowIsDeactivated():Void
	{
		var window = open();
		if (window == null) return;

		var states = [];
		event(DEACTIVATE, window.id);
		states.push(AudioManager.__suspended);
		event(ACTIVATE, window.id);
		states.push(AudioManager.__suspended);

		Assert.equals("true,false", states.join(","));
	}

	public function testTimersWaitWhileTheWindowIsDeactivated():Void
	{
		var window = open();
		if (window == null) return;

		var timer = new Timer(60000);
		var due:Float = @:privateAccess timer.mFireAt;

		var outside = System.getTimer();
		event(DEACTIVATE, window.id);
		var inside = System.getTimer();
		Sys.sleep(0.05);
		inside = System.getTimer() - inside;
		event(ACTIVATE, window.id);
		outside = System.getTimer() - outside;

		var waited:Float = @:privateAccess timer.mFireAt - due;
		timer.stop();

		// The timer is put off by the time the window was deactivated for
		Assert.isTrue(waited >= inside && waited <= outside,
			"a timer was put off by " + waited + " ms for a window deactivated for " + inside + " to " + outside + " ms");
	}

	public function testActivatingAWindowThatWasActiveMovesNoTimer():Void
	{
		var window = open();
		if (window == null) return;

		var timer = new Timer(60000);
		var due:Float = @:privateAccess timer.mFireAt;

		Sys.sleep(0.01);
		event(ACTIVATE, window.id);
		event(ACTIVATE, window.id);

		var waited:Float = @:privateAccess timer.mFireAt - due;
		timer.stop();

		Assert.equals(0.0, waited);
	}

	public function testACloseRequestClosesTheWindow():Void
	{
		if (open() == null) return;

		var closing = create();
		var closes = 0;
		closing.onClose.add(function() closes++);

		event(CLOSE, closing.id);

		Assert.equals(1, closes);
		Assert.isNull(closing.nativeHandle, "the window was not closed");
		Assert.equals(-1, Application.current.windows.indexOf(closing));
	}

	public function testACanceledCloseRequestLeavesTheWindowOpen():Void
	{
		if (open() == null) return;

		var closing = create();
		var cancel = function() closing.onClose.cancel();
		closing.onClose.add(cancel);

		event(CLOSE, closing.id);
		var stayedOpen = closing.nativeHandle != null && Application.current.windows.indexOf(closing) != -1;

		// It can still be closed once nothing cancels it
		closing.onClose.remove(cancel);
		event(CLOSE, closing.id);

		Assert.isTrue(stayedOpen, "a window was closed though its close was canceled");
		Assert.isNull(closing.nativeHandle, "the window was not closed once its close was no longer canceled");
	}

	public function testAClosedWindowHearsNoMoreEvents():Void
	{
		if (open() == null) return;

		var closing = create();
		var id = closing.id;
		event(CLOSE, id);

		var heard = [];
		listen(closing, "", heard);
		closing.onClose.add(function() heard.push("close"));

		for (type in [DEACTIVATE, ACTIVATE, CLOSE, ENTER, EXPOSE, FOCUS_IN, FOCUS_OUT, LEAVE, MAXIMIZE, MINIMIZE, MOVE, RESIZE, RESTORE, SHOW, HIDE])
		{
			event(type, id, 5, 6, 7, 8);
		}

		Assert.equals("", heard.join(","));
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
			if (!reported) trace("No window can be created here, so window events were not tested");
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
			title: "WindowEventTest"
		});
	}

	private static function state(window:Window):String
	{
		var state = [];

		if (window.minimized) state.push("minimized");
		if (window.maximized) state.push("maximized");

		return state.join("+");
	}

	private static function listen(window:Window, name:String, heard:Array<String>):Void
	{
		window.onActivate.add(function() heard.push(name + "activate"));
		window.onDeactivate.add(function() heard.push(name + "deactivate"));
		window.onEnter.add(function() heard.push(name + "enter"));
		window.onExpose.add(function() heard.push(name + "expose"));
		window.onFocusIn.add(function() heard.push(name + "focusIn"));
		window.onFocusOut.add(function() heard.push(name + "focusOut"));
		window.onFullscreen.add(function() heard.push(name + "fullscreen"));
		window.onLeave.add(function() heard.push(name + "leave"));
		window.onMaximize.add(function() heard.push(name + "maximize"));
		window.onMinimize.add(function() heard.push(name + "minimize"));
		window.onMove.add(function(x:Float, y:Float) heard.push(name + "move"));
		window.onResize.add(function(width:Int, height:Int) heard.push(name + "resize"));
		window.onRestore.add(function() heard.push(name + "restore"));
		window.onShow.add(function() heard.push(name + "show"));
		window.onHide.add(function() heard.push(name + "hide"));
		window.onDisplayScaleChange.add(function() heard.push(name + "scale"));
	}

	private static function shortcut(window:Window):Void
	{
		// Alt+Enter, or Ctrl+Command+F on macOS, pressed and released
		var keyCode = #if mac KeyCode.F #else KeyCode.RETURN #end;
		var modifier = #if mac KeyModifier.LEFT_CTRL | KeyModifier.LEFT_META #else KeyModifier.LEFT_ALT #end;
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.keyEventInfo;
		var code:Int = keyCode;
		info.windowID = window.id;
		info.keyCode = code;
		info.modifier = modifier;
		info.timestamp = 0;

		for (type in 0...2)
		{
			info.type = cast type;
			@:privateAccess backend.handleKeyEvent();
		}
	}

	private static function event(type:Int, windowID:Int, x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0):Void
	{
		// The event as native code fills it in, then the handler it calls
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.windowEventInfo;
		info.type = cast type;
		info.windowID = windowID;
		info.x = x;
		info.y = y;
		info.width = width;
		info.height = height;
		@:privateAccess backend.handleWindowEvent();
	}
	#end
}
