package ui;

import haxe.Timer;
import lime.app.Application;
import lime.system.Display;
import lime.system.DisplayMode;
import lime.system.System;
import lime.ui.Window;
import lime.ui.WindowAttributes;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	Where a window opens, and how it goes fullscreen, from its `WindowAttributes`.

	`display` is the index of the display to open on, as `System.getDisplay()` takes it: the window
	is centered on it unless `x` and `y` are given, which are on the whole desktop, a fullscreen
	window fills it, and a display that isn't connected gives the primary one. `displayMode` with
	`fullscreen` opens the window in exclusive fullscreen at that mode; without `fullscreen`, it is
	the mode the window uses once it goes fullscreen. `Window.minimizeOnFocusLoss` says whether an
	exclusive fullscreen window minimizes when it loses focus, `true` unless it is turned off. And a
	window that entered or left fullscreen, or that the system restored while fullscreen, dispatches
	`onExpose`, so an application that draws only when asked draws again (#2083).

	Windows are opened hidden. A display that isn't here, such as a second monitor, can't be tried,
	so the tests try each display that is. The exclusive fullscreen window asks for the display's
	own mode, so the screen never changes mode.
**/
class WindowDisplayTest extends Test
{
	#if (lime_cffi && !macro && (windows || mac || linux) && !rpi)
	private static inline var RESTORE = 12;

	private var opened:Array<Window> = [];
	private var reported:Bool = false;
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && (windows || mac || linux) && !rpi)
	public function teardown():Void
	{
		for (window in opened)
		{
			window.onExpose.removeAll();
			if (window.fullscreen) window.fullscreen = false;
			// Closing the last window of the application ends it, so that one is left open, hidden
			if (Application.current.windows.length > 1) window.close();
		}

		opened = [];
	}

	public function testAWindowOpensCenteredOnTheDisplayItAsksFor():Void
	{
		if (!hasDisplays()) return;

		for (index in 0...System.numDisplays)
		{
			var window = open({width: 200, height: 100, display: index});
			if (window == null) return;

			var bounds = System.getDisplay(index).bounds;
			Assert.equals(index, window.display != null ? window.display.id : -1, "the display of a window asking for display " + index);
			assertCentered(window, bounds, "on display " + index);
		}
	}

	public function testAWindowOnADisplayThatIsNotConnectedOpensOnThePrimaryOne():Void
	{
		if (!hasDisplays()) return;

		for (index in [System.numDisplays, System.numDisplays + 7, -1])
		{
			var window = open({width: 200, height: 100, display: index});
			if (window == null) return;

			Assert.equals(0, window.display != null ? window.display.id : -1, "the display of a window asking for display " + index);
			assertCentered(window, System.getDisplay(0).bounds, "asking for display " + index);
		}
	}

	public function testAWindowOpensWhereXAndYSay():Void
	{
		if (!hasDisplays()) return;

		// A place on the primary display, away from its corner, where nothing would put the window itself
		var bounds = System.getDisplay(0).bounds;
		var x = Std.int(bounds.x) + 37;
		var y = Std.int(bounds.y) + 53;
		var window = open({width: 64, height: 64, x: x, y: y});
		if (window == null) return;

		Assert.equals(x + "," + y, window.x + "," + window.y, "the window's position");
	}

	public function testAWindowGivenOnlyXIsCenteredUpAndDown():Void
	{
		if (!hasDisplays()) return;

		var bounds = System.getDisplay(0).bounds;
		var x = Std.int(bounds.x) + 37;
		var window = open({width: 64, height: 64, x: x});
		if (window == null) return;

		Assert.equals(x, window.x, "x");
		assertNear(bounds.y + (bounds.height - window.height) / 2, window.y, "y, centered on the display");

		var y = Std.int(bounds.y) + 53;
		var other = open({width: 64, height: 64, y: y});
		if (other == null) return;

		assertNear(bounds.x + (bounds.width - other.width) / 2, other.x, "x, centered on the display");
		Assert.equals(y, other.y, "y");
	}

	public function testAFullscreenWindowIsFullscreenOnTheDisplayItAsksFor():Void
	{
		if (!hasDisplays()) return;

		for (index in 0...System.numDisplays)
		{
			var window = open({width: 64, height: 64, display: index, fullscreen: true});
			if (window == null) return;

			Assert.isTrue(window.fullscreen, "a window created fullscreen on display " + index + " says it is not");
			Assert.equals(index, window.display != null ? window.display.id : -1, "the display of a fullscreen window asking for display " + index);
		}
	}

	public function testAWindowCreatedFullscreenAtADisplayModeUsesIt():Void
	{
		if (!hasDisplays()) return;

		// The display's own mode, so that nothing about the screen changes
		var mode = System.getDisplay(0).currentMode;
		if (mode == null)
		{
			Assert.pass("the display gives no current mode here");
			return;
		}

		var window = open({width: 64, height: 64, display: 0, fullscreen: true, displayMode: mode});
		if (window == null) return;

		Assert.isTrue(window.fullscreen, "a window created fullscreen at a display mode says it is not fullscreen");
		Assert.equals(describe(mode), describe(window.displayMode), "the window's display mode");
	}

	public function testADisplayModeWithoutFullscreenIsTheModeForFullscreen():Void
	{
		if (!hasDisplays()) return;

		// A mode the display supports that it isn't in, which a window that only asked for it can't be
		// reporting by chance. The window is not fullscreen, so the screen keeps its own mode.
		var display = System.getDisplay(0);
		var mode = otherMode(display);
		if (mode == null)
		{
			Assert.pass("the display supports only the mode it is in here, so there is no other mode to ask for");
			return;
		}

		var window = open({width: 64, height: 64, display: 0, displayMode: mode});
		if (window == null) return;

		Assert.isFalse(window.fullscreen, "a window given only a display mode went fullscreen");
		Assert.equals(describe(mode), describe(window.displayMode), "the mode the window would use in fullscreen");
	}

	// SDL can give a window's mode no refresh rate, as on Linux, where its display's current mode
	// has one, which the window's mode then gives (#1951)
	public function testAWindowGivenItsDisplaysModeHasItsRefreshRate():Void
	{
		if (!hasDisplays()) return;

		var mode = currentModeWithARefreshRate(System.getDisplay(0));
		if (mode == null) return;

		var window = open({width: 64, height: 64, display: 0, displayMode: mode});
		if (window == null) return;

		Assert.equals(describe(mode), describe(window.displayMode), "the display mode of a window given its display's own");
	}

	// A window's mode is the display mode nearest its size, which can run at another rate than the
	// display does now, but not at none where the display's mode has one (#1951)
	public function testAWindowsDisplayModeHasARefreshRateWhereItsDisplayHasOne():Void
	{
		if (!hasDisplays()) return;

		var window = open({width: 200, height: 150});
		if (window == null) return;

		var display = window.display;
		var mode = currentModeWithARefreshRate(display);
		if (mode == null) return;

		var windowMode = window.displayMode;
		Assert.isTrue(windowMode.refreshRate > 0, "the window's display mode is " + describe(windowMode) + ", where its display's is " + describe(mode));
		Assert.isTrue(windowMode.width >= 200 && windowMode.height >= 150, "the window's display mode is " + describe(windowMode) + ", smaller than the window");
	}

	public function testMinimizeOnFocusLossIsOnUntilTurnedOff():Void
	{
		var window = open({width: 64, height: 64});
		var other = open({width: 64, height: 64});
		if (window == null || other == null) return;

		Assert.isTrue(window.minimizeOnFocusLoss, "a new window");

		window.minimizeOnFocusLoss = false;
		Assert.isFalse(window.minimizeOnFocusLoss, "once turned off");
		Assert.isTrue(other.minimizeOnFocusLoss, "another window, once the first turned it off");

		window.minimizeOnFocusLoss = true;
		Assert.isTrue(window.minimizeOnFocusLoss, "once turned back on");
	}

	@:timeout(10000)
	public function testEnteringAndLeavingFullscreenExposeTheWindow(async:Async):Void
	{
		var window = open({width: 64, height: 64});
		if (window == null)
		{
			async.done();
			return;
		}

		var heard = [];
		window.onExpose.add(function() heard.push(window.fullscreen ? "fullscreen" : "windowed"));

		// Frames are drawn between the changes, which is when a window that changed is exposed
		window.fullscreen = true;
		Timer.delay(function()
		{
			var entering = heard.join(",");
			heard.splice(0, heard.length);
			window.fullscreen = false;

			Timer.delay(function()
			{
				var leaving = heard.join(",");
				Assert.isTrue(entering.indexOf("fullscreen") > -1, "onExpose once the window entered fullscreen: heard \"" + entering + "\"");
				Assert.isTrue(leaving.indexOf("windowed") > -1, "onExpose once the window left fullscreen: heard \"" + leaving + "\"");
				Assert.equals(-1, leaving.indexOf("fullscreen"), "onExpose said the window was still fullscreen: heard \"" + leaving + "\"");
				async.done();
			}, 500);
		}, 500);
	}

	private function open(attributes:WindowAttributes):Window
	{
		// The application listens to the first window it is given, which these tests leave alone, open
		if (Application.current.window == null)
		{
			Application.current.createWindow({width: 64, height: 64, hidden: true, title: "WindowDisplayTest"});
		}

		attributes.hidden = true;
		attributes.title = "WindowDisplayTest";

		var window = Application.current.createWindow(attributes);
		if (window == null)
		{
			// Without a display, as on the Linux runners, no window can be created.
			// utest takes a warning as a failure, so the test passes, saying why
			if (!reported) trace("No window can be created here, so where windows open was not tested");
			reported = true;
			Assert.pass();
			return null;
		}

		opened.push(window);
		return window;
	}

	/** A window event as native code fills it in, handed to the handler it calls **/
	private static function event(type:Int, windowID:Int):Void
	{
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.windowEventInfo;
		info.type = cast type;
		info.windowID = windowID;
		info.x = 0;
		info.y = 0;
		info.width = 0;
		info.height = 0;
		@:privateAccess backend.handleWindowEvent();
	}

	@:timeout(10000)
	public function testAFullscreenWindowRestoredBySystemIsExposed(async:Async):Void
	{
		// As when a fullscreen window that was minimized, or left for another, comes back
		var window = open({width: 64, height: 64});
		if (window == null)
		{
			async.done();
			return;
		}

		var heard = 0;
		window.onExpose.add(function() heard++);

		window.fullscreen = true;
		Timer.delay(function()
		{
			heard = 0;
			event(RESTORE, window.id);

			Timer.delay(function()
			{
				Assert.isTrue(heard > 0, "onExpose once the system restored the fullscreen window");
				async.done();
			}, 500);
		}, 500);
	}

	private static function hasDisplays():Bool
	{
		if (System.numDisplays > 0) return true;

		// Without a display, as on the Linux runners, there is nowhere to open a window
		Assert.pass("there is no display here");
		return false;
	}

	private static function assertCentered(window:Window, bounds:lime.math.Rectangle, label:String, ?pos:haxe.PosInfos):Void
	{
		assertNear(bounds.x + (bounds.width - window.width) / 2, window.x, label + ": x", pos);
		assertNear(bounds.y + (bounds.height - window.height) / 2, window.y, label + ": y", pos);
	}

	/** Within a pixel, as half of an odd difference is rounded either way **/
	private static function assertNear(expected:Float, actual:Float, label:String, ?pos:haxe.PosInfos):Void
	{
		Assert.isTrue(Math.abs(expected - actual) <= 1, label + ": expected " + expected + " but was " + actual, pos);
	}

	/**
		The current mode of `display`, or null when it has none here or SDL gives it no refresh rate,
		as may be so under Xvfb, passing the test, saying why.
	**/
	private static function currentModeWithARefreshRate(display:Display):DisplayMode
	{
		var mode = display != null ? display.currentMode : null;

		if (mode == null)
		{
			Assert.pass("the window's display gives no current mode here");
			return null;
		}

		if (mode.refreshRate <= 0)
		{
			// utest takes a warning as a failure, so the test passes, saying why
			trace("SDL gives no refresh rate for the display's mode here, " + describe(mode) + ", so a window's was not compared with it");
			Assert.pass();
			return null;
		}

		return mode;
	}

	private static function otherMode(display:Display):DisplayMode
	{
		var current = describe(display.currentMode);
		if (display.supportedModes == null) return null;

		for (mode in display.supportedModes)
		{
			if (describe(mode) != current) return mode;
		}

		return null;
	}

	private static function describe(mode:DisplayMode):String
	{
		if (mode == null) return "null";
		return mode.width + "x" + mode.height + " at " + mode.refreshRate + " Hz, format " + Std.string(mode.pixelFormat);
	}
	#end

	#if (js && html5)
	@:timeout(10000)
	public function testMinimizeOnFocusLossIsKeptForTheApplicationsWindow(async:Async):Void
	{
		// Nothing minimizes a window on HTML5, so the setting is only kept
		var timer = new Timer(10);
		var started = false;
		timer.run = function()
		{
			var window = Application.current != null ? Application.current.window : null;
			// A run already queued can come after stop()
			if (started || window == null) return;
			started = true;
			timer.stop();

			Assert.isTrue(window.minimizeOnFocusLoss, "the application's window");
			window.minimizeOnFocusLoss = false;
			Assert.isFalse(window.minimizeOnFocusLoss, "once turned off");
			window.minimizeOnFocusLoss = true;
			Assert.isTrue(window.minimizeOnFocusLoss, "once turned back on");
			async.done();
		};
	}
	#end
}
