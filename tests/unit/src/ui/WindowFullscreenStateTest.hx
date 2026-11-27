package ui;

import haxe.Timer;
import lime.app.Application;
import lime.ui.Window;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	`Window.fullscreen` through the events the system sends as a window is minimized, restored and
	maximized. SDL keeps a fullscreen window fullscreen while it is minimized, as Alt+Tab minimizes
	one, and puts it back in fullscreen once it is restored, and Windows restores a maximized window
	as it takes it fullscreen. Each of those events used to say the window had left fullscreen
	(#873, #1771, #2081), where `fullscreen` now reads what SDL says.

	The windows are shown, as a hidden window can't be minimized everywhere, so these tests take a
	window fullscreen on the desktop.
**/
class WindowFullscreenStateTest extends Test
{
	#if (lime_cffi && !macro && (windows || mac || linux) && !rpi)
	// How long a window event may take, and how long the events that follow a change take to come
	private static inline var EVENT_SECONDS = 10;
	private static inline var SETTLE_MS = 1500;

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
			window.onMaximize.removeAll();
			window.onMinimize.removeAll();
			window.onRestore.removeAll();
			if (window.fullscreen || getFullscreen(window)) window.fullscreen = false;
			// Closing the last window of the application ends it, so that one is left open, hidden
			if (Application.current.windows.length > 1) window.close();
		}

		opened = [];
	}

	public function testSDLSaysWhatWasSet():Void
	{
		var window = open();
		if (window == null) return;

		window.fullscreen = true;
		Assert.isTrue(getFullscreen(window), "SDL says a window set fullscreen is not");
		Assert.isTrue(window.fullscreen, "a window set fullscreen says it is not");

		window.fullscreen = false;
		Assert.isFalse(getFullscreen(window), "SDL says a window set back from fullscreen still is");
		Assert.isFalse(window.fullscreen, "a window set back from fullscreen says it still is");
	}

	// As when the user switches to another application and back (#873, #1771)
	@:timeout(30000)
	public function testAFullscreenWindowIsStillFullscreenWhileMinimizedAndOnceRestored(async:Async):Void
	{
		var window = open();
		if (window == null)
		{
			async.done();
			return;
		}

		window.fullscreen = true;

		settle(function()
		{
			var whileMinimized:Null<Bool> = null;
			window.onMinimize.add(function() whileMinimized = window.fullscreen);
			window.minimized = true;

			waitFor(function() return whileMinimized != null, function(minimizeHeard)
			{
				if (!minimizeHeard)
				{
					notSent("minimize", async);
					return;
				}

				Assert.isTrue(whileMinimized == true, "a fullscreen window says it is not once it is minimized");

				settle(function()
				{
					Assert.isTrue(window.fullscreen, "a fullscreen window says it is not while it is minimized");

					var onceRestored:Null<Bool> = null;
					window.onRestore.add(function() onceRestored = window.fullscreen);
					window.minimized = false;

					waitFor(function() return onceRestored != null, function(restoreHeard)
					{
						if (!restoreHeard)
						{
							notSent("restore", async);
							return;
						}

						Assert.isTrue(onceRestored == true, "a fullscreen window says it is not once it is restored");

						settle(function()
						{
							Assert.isTrue(window.fullscreen, "a fullscreen window says it is not after the events that follow its restore");
							Assert.isTrue(getFullscreen(window), "SDL says the window is not fullscreen once restored");
							async.done();
						});
					});
				});
			});
		});
	}

	// The restore event as a maximized window goes fullscreen used to clear it right after the set (#2081)
	@:timeout(30000)
	public function testAMaximizedWindowSetFullscreenStaysFullscreen(async:Async):Void
	{
		var window = open();
		if (window == null)
		{
			async.done();
			return;
		}

		maximize(window, function()
		{
			Assert.isFalse(window.fullscreen, "a maximized window says it is fullscreen");

			window.fullscreen = true;

			settle(function()
			{
				Assert.isTrue(window.fullscreen, "a maximized window set fullscreen says it is not after the events that follow");
				Assert.isTrue(getFullscreen(window), "SDL says the maximized window set fullscreen is not");
				async.done();
			});
		}, async);
	}

	@:timeout(30000)
	public function testAWindowSetBackFromFullscreenIsNot(async:Async):Void
	{
		var window = open();
		if (window == null)
		{
			async.done();
			return;
		}

		window.fullscreen = true;

		settle(function()
		{
			window.fullscreen = false;

			settle(function()
			{
				Assert.isFalse(window.fullscreen, "a window set back from fullscreen says it still is after the events that follow");
				Assert.isFalse(getFullscreen(window), "SDL says a window set back from fullscreen still is");
				async.done();
			});
		});
	}

	@:timeout(30000)
	public function testAWindowThatIsNotFullscreenIsNotOnceMaximizedOrRestored(async:Async):Void
	{
		var window = open();
		if (window == null)
		{
			async.done();
			return;
		}

		maximize(window, function()
		{
			Assert.isFalse(window.fullscreen, "a window that is not fullscreen says it is once maximized");

			var restored = false;
			window.onRestore.add(function() restored = true);
			window.maximized = false;

			waitFor(function() return restored, function(heard)
			{
				if (!heard)
				{
					notSent("restore", async);
					return;
				}

				Assert.isFalse(window.fullscreen, "a window that is not fullscreen says it is once restored");
				Assert.isFalse(getFullscreen(window), "SDL says a window that was only maximized and restored is fullscreen");
				async.done();
			});
		}, async);
	}

	/**
		Maximizes `window` and calls `then` once its maximize event came, or ends the test if it
		didn't come.
	**/
	private function maximize(window:Window, then:Void->Void, async:Async):Void
	{
		var maximized = false;
		window.onMaximize.add(function() maximized = true);
		window.maximized = true;

		waitFor(function() return maximized, function(heard)
		{
			if (!heard)
			{
				notSent("maximize", async);
				return;
			}

			settle(then);
		});
	}

	private function open():Window
	{
		// The application listens to the first window it is given, which these tests leave alone, open
		if (Application.current.window == null)
		{
			Application.current.createWindow({width: 64, height: 64, hidden: true, title: "WindowFullscreenStateTest"});
		}

		// SDL maximizes only a resizable window
		var window = Application.current.createWindow({width: 200, height: 150, resizable: true, title: "WindowFullscreenStateTest"});
		if (window == null)
		{
			// Without a display, as on the Linux runners, no window can be created.
			// utest takes a warning as a failure, so the test passes, saying why
			if (!reported) trace("No window can be created here, so fullscreen through window events was not tested");
			reported = true;
			Assert.pass();
			return null;
		}

		opened.push(window);
		return window;
	}

	/**
		Ends a test whose window got no `event` event. A window system can leave a change undone, as
		X11 without a window manager does under Xvfb, so the test passes, saying what was not tested.
	**/
	private static function notSent(event:String, async:Async):Void
	{
		trace("No " + event + " event came within " + EVENT_SECONDS + " seconds, so the fullscreen state after it was not tested");
		Assert.pass();
		async.done();
	}

	/** What SDL says of the window, as the window events read it **/
	private static function getFullscreen(window:Window):Bool
	{
		return @:privateAccess window.__backend.getFullscreen();
	}

	/** Waits for the events that follow a change, then calls `then` **/
	private static function settle(then:Void->Void):Void
	{
		Timer.delay(then, SETTLE_MS);
	}

	private static function waitFor(condition:Void->Bool, then:Bool->Void):Void
	{
		var deadline = Timer.stamp() + EVENT_SECONDS;
		var timer = new Timer(16);
		timer.run = function()
		{
			var met = condition();
			if (met || Timer.stamp() > deadline)
			{
				timer.stop();
				then(met);
			}
		};
	}
	#end
}
