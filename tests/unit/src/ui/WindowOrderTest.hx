package ui;

import lime.app.Application;
import lime.ui.Window;
import lime.ui.WindowEdge;
import utest.Assert;
import utest.Test;

/**
	`Window.orderToBack`, `orderAbove` and `orderBelow`, which change where a
	window is stacked, and `startMove` and `startResize`, which only start
	while the left button is held, so here they only refuse to.

	Native windows do this through native-desktop, from 1.2.0. With an older
	native-desktop every call returns `false`, and the tests say so and pass.
**/
class WindowOrderTest extends Test
{
	public function new()
	{
		super();
	}

	public function testEdgesCombineIntoCorners():Void
	{
		Assert.equals(1, (WindowEdge.TOP : Int));
		Assert.equals(2, (WindowEdge.BOTTOM : Int));
		Assert.equals(4, (WindowEdge.LEFT : Int));
		Assert.equals(8, (WindowEdge.RIGHT : Int));
		Assert.equals(WindowEdge.TOP | WindowEdge.LEFT, (WindowEdge.TOP_LEFT : Int));
		Assert.equals(WindowEdge.TOP | WindowEdge.RIGHT, (WindowEdge.TOP_RIGHT : Int));
		Assert.equals(WindowEdge.BOTTOM | WindowEdge.LEFT, (WindowEdge.BOTTOM_LEFT : Int));
		Assert.equals(WindowEdge.BOTTOM | WindowEdge.RIGHT, (WindowEdge.BOTTOM_RIGHT : Int));
	}

	#if (lime_cffi && !macro && (windows || mac || linux))
	private static var first:Window;
	private static var second:Window;

	public function testAWindowIsNotOrderedAgainstItselfOrNothing():Void
	{
		if (!open()) return;

		Assert.isFalse(first.orderAbove(first));
		Assert.isFalse(first.orderBelow(first));
		Assert.isFalse(first.orderAbove(null));
		Assert.isFalse(first.orderBelow(null));
	}

	public function testMovingAndResizingNeedTheButtonHeld():Void
	{
		if (!open()) return;

		var moved = first.startMove();
		var resized = first.startResize(BOTTOM_RIGHT);
		Assert.isFalse(first.startResize(cast 0));

		// The system reads the real button, which someone using the machine may hold, but nobody does on CI
		if ((moved || resized) && Sys.getEnv("CI") != "true")
		{
			trace("The left button was held, so only an edge of 0 was refused");
			return;
		}

		Assert.isFalse(moved, "a move started with the left button up");
		Assert.isFalse(resized, "a resize started with the left button up");
	}

	public function testWindowsAreStackedAsAsked():Void
	{
		if (!open()) return;

		var toBack = first.orderToBack();

		#if mac
		#if (native_desktop >= "1.2.1")
		// AppKit shows a window to order it, so hidden windows are left alone, and stay hidden
		Assert.isFalse(toBack, "a hidden window was ordered to the back");
		Assert.isFalse(first.orderAbove(second), "a hidden window was ordered above another");
		Assert.isFalse(first.orderBelow(second), "a hidden window was ordered below another");
		#end

		// Shown windows are stacked as asked. They are closed after, so none is left on screen
		var shown = Application.current.createWindow({width: 64, height: 64, title: "WindowOrderTest shown"});
		var other = Application.current.createWindow({width: 64, height: 64, title: "WindowOrderTest shown other"});
		var above = shown != null && other != null && shown.orderAbove(other);
		var below = shown != null && other != null && shown.orderBelow(other);
		var back = shown != null && shown.orderToBack();
		if (shown != null) shown.close();
		if (other != null) other.close();

		if (!isSupported(back)) return;
		Assert.isTrue(above, "first.orderAbove(second) was refused for shown windows");
		Assert.isTrue(below, "first.orderBelow(second) was refused for shown windows");
		#else
		if (!isSupported(toBack)) return;

		#if windows
		Assert.isTrue(isAbove(second, first), "the second window is not above the first after first.orderToBack()");

		Assert.isTrue(first.orderAbove(second));
		Assert.isTrue(isAbove(first, second), "the first window is not above the second after first.orderAbove(second)");

		Assert.isTrue(first.orderBelow(second));
		Assert.isTrue(isAbove(second, first), "the second window is not above the first after first.orderBelow(second)");

		Assert.isTrue(second.orderBelow(first));
		Assert.isTrue(isAbove(first, second), "the first window is not above the second after second.orderBelow(first)");
		#else
		// The window manager decides on X11, and may refuse
		first.orderAbove(second);
		Assert.pass();
		#end
		#end
	}

	private static function open():Bool
	{
		if (first == null)
		{
			// The application listens to the first window it is given, and the
			// windows are left open, hidden, as closing the last one ends it
			if (Application.current.window == null) create("WindowOrderTest");
			first = create("WindowOrderTest first");
			second = create("WindowOrderTest second");
		}

		if (first == null || second == null)
		{
			// utest takes a warning as a failure, so the test passes, saying why
			trace("No window can be created here, so windows were not ordered");
			Assert.pass();
			return false;
		}

		return true;
	}

	private static function create(title:String):Window
	{
		return Application.current.createWindow({width: 64, height: 64, hidden: true, title: title});
	}

	private static function isSupported(result:Bool):Bool
	{
		if (result) return true;

		#if (native_desktop >= "1.2.0" && windows)
		Assert.fail("orderToBack() did not order the window");
		#else
		trace("native-desktop " + haxe.macro.Compiler.getDefine("native-desktop") + " does not order windows here, so ordering was not tested");
		Assert.pass();
		#end
		return false;
	}

	#if windows
	/**
		Whether `upper` is stacked above `lower`, found by walking down the
		windows from `upper`, through PowerShell.
	**/
	private static function isAbove(upper:Window, lower:Window):Bool
	{
		var script = "Add-Type -Namespace LimeTest -Name Order -MemberDefinition '[DllImport(\"user32.dll\")] public static extern IntPtr GetWindow(IntPtr hWnd, uint command);'\n"
			+ "$window = [IntPtr][Int64]" + haxe.Int64.toStr(upper.nativeHandle.window) + "\n"
			+ "$lower = [IntPtr][Int64]" + haxe.Int64.toStr(lower.nativeHandle.window) + "\n"
			// GW_HWNDNEXT, the window below
			+ "while ($window -ne [IntPtr]::Zero) { $window = [LimeTest.Order]::GetWindow($window, 2); if ($window -eq $lower) { exit 0 } }\n"
			+ "exit 1\n";

		// An encoded command is UTF-16, and needs no quoting
		var utf16 = haxe.io.Bytes.alloc(script.length * 2);
		for (i in 0...script.length)
		{
			utf16.setUInt16(i * 2, StringTools.fastCodeAt(script, i));
		}

		// HashLink starts a process by its path, without looking through PATH
		var root = Sys.getEnv("SystemRoot");
		var path = root != null ? root + "\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" : null;
		var executable = path != null && sys.FileSystem.exists(path) ? path : "powershell";

		var process = new sys.io.Process(executable, ["-NoProfile", "-NonInteractive", "-EncodedCommand", haxe.crypto.Base64.encode(utf16)]);
		var exitCode = process.exitCode();
		process.close();
		return exitCode == 0;
	}
	#end
	#else
	@:timeout(10000)
	public function testWindowsCannotBeOrderedOrMoved(async:utest.Async):Void
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

			// Browsers and Flash do not let a page order or move its window
			Assert.isFalse(window.orderToBack());
			Assert.isFalse(window.orderBelow(window));
			Assert.isFalse(window.startMove());
			Assert.isFalse(window.startResize(BOTTOM_RIGHT));
			async.done();
		};
	}
	#end
}
