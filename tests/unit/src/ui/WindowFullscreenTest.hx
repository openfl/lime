package ui;

import haxe.Timer;
import lime.app.Application;
import lime.ui.Window;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	Leaving fullscreen on Windows gives back a window that fits the display it is
	on, with the shape it had, as Windows restores a window at its windowed size
	even when that no longer fits, and takes a window whose client area covers
	the display for a fullscreen one. A maximized window stays maximized.
**/
class WindowFullscreenTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && windows && !winrt)
	private var window:Window;

	public function teardown():Void
	{
		if (window != null)
		{
			window.close();
			window = null;
		}
	}

	@:timeout(15000)
	public function testLeavingFullscreenFitsAWindowLargerThanTheDisplay(async:Async):Void
	{
		var display = Application.current.window.display;
		if (display == null)
		{
			Assert.pass("no display");
			async.done();
			return;
		}

		var width = Std.int(display.bounds.width);
		var height = Std.int(display.bounds.height);
		window = Application.current.createWindow({width: width, height: height, title: "WindowFullscreenTest large"});

		toggle(window, function()
		{
			Assert.isFalse(window.fullscreen);
			Assert.isTrue(window.width < width && window.height < height,
				'a ${width}x${height} window came back from fullscreen at ${window.width}x${window.height}, on a ${width}x${height} display');
			// The same shape, to a pixel
			Assert.isTrue(Math.abs(window.width / window.height - width / height) < 2 / window.height,
				'the window came back at ${window.width}x${window.height}, not the shape of ${width}x${height}');
			async.done();
		});
	}

	@:timeout(15000)
	public function testLeavingFullscreenKeepsAWindowThatFitsAsItWas(async:Async):Void
	{
		window = Application.current.createWindow({width: 320, height: 240, title: "WindowFullscreenTest small"});

		toggle(window, function()
		{
			Assert.equals(320, window.width);
			Assert.equals(240, window.height);
			async.done();
		});
	}

	@:timeout(15000)
	public function testLeavingFullscreenKeepsAMaximizedWindowMaximized(async:Async):Void
	{
		window = Application.current.createWindow({width: 320, height: 240, title: "WindowFullscreenTest maximized"});
		window.maximized = true;

		wait(function() return window.width > 320, function(_)
		{
			var maximizedWidth = window.width;
			var maximizedHeight = window.height;

			toggle(window, function()
			{
				Assert.isTrue(window.maximized, "the window was maximized before fullscreen and not after");
				Assert.equals(maximizedWidth, window.width);
				Assert.equals(maximizedHeight, window.height);
				async.done();
			});
		});
	}

	// Makes the window fullscreen and back, and calls done once its size has settled
	private static function toggle(window:Window, done:Void->Void):Void
	{
		window.fullscreen = true;

		wait(function() return window.fullscreen, function(_)
		{
			window.fullscreen = false;

			var lastWidth = -1;
			var lastHeight = -1;
			var steady = 0;

			// The size arrives with the window's events, a few frames later
			wait(function()
			{
				if (window.width == lastWidth && window.height == lastHeight) steady++ else steady = 0;
				lastWidth = window.width;
				lastHeight = window.height;
				return steady >= 10;
			}, function(_) done());
		});
	}

	private static function wait(condition:Void->Bool, then:Bool->Void, seconds:Float = 5):Void
	{
		var deadline = Timer.stamp() + seconds;
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
