package app;

#if (js && html5)
import lime.app.Application;
import lime.ui.Joystick;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	What an HTML5 application asks of the browser on every frame.

	Each frame reads the size of the window's element, which makes the browser finish its layout first,
	and asks for the gamepads, which makes a new snapshot of them. With a `ResizeObserver` the size can be
	read only when it changes, and with `gamepadconnected` the gamepads only once one has connected.
	Resizing the element still resizes the window, and a gamepad that connects is still polled.

	These run only in a browser, which CI doesn't run the unit tests in.
**/
class HTML5FrameTest extends Test
{
	public function new()
	{
		super();
	}

	#if (js && html5)
	@Ignored("Waiting on #2133")
	@:timeout(10000)
	public function testTheElementSizeIsNotReadEveryFrame(async:Async):Void
	{
		if (js.Syntax.code("typeof ResizeObserver") == "undefined")
		{
			trace("This browser has no ResizeObserver, so the size is read every frame");
			Assert.pass();
			async.done();
			return;
		}

		withWindow(function()
		{
			var element = Application.current.window.element;
			var reads = spyOnSize(element);

			waitFrames(30, function()
			{
				var count = reads();
				Assert.isTrue(count <= 4, "the element's size was read " + count + " times in 30 frames");
				async.done();
			});
		});
	}

	@:timeout(10000)
	public function testResizingTheElementResizesTheWindow(async:Async):Void
	{
		withWindow(function() resizes(async));
	}

	private static function resizes(async:Async):Void
	{
		var window = Application.current.window;
		var element = window.element;
		var previous = element.style.width;
		var heard = [];
		var listener = function(width:Int, height:Int) heard.push(width);
		window.onResize.add(listener);

		element.style.width = "321px";

		waitFrames(10, function()
		{
			window.onResize.remove(listener);
			var width = window.width;
			element.style.width = previous;

			Assert.equals(321, width);
			Assert.isTrue(heard.indexOf(321) > -1, "the window heard " + heard.join(", "));
			waitFrames(5, function() async.done());
		});
	}

	@:timeout(10000)
	public function testAResizeReachesTheWindowWithinAFewFrames(async:Async):Void
	{
		withWindow(function() resizesSoon(async));
	}

	private static function resizesSoon(async:Async):Void
	{
		// The size can come a frame later from a ResizeObserver, which reports after layout, than from
		// reading it each frame, but not much later
		var window = Application.current.window;
		var element = window.element;
		var previous = element.style.width;
		var frames = 0;
		var heardAt = -1;
		var listener = function(width:Int, height:Int) if (width == 333 && heardAt < 0) heardAt = frames;
		var counter = function(_:Int) frames++;
		window.onResize.add(listener);
		Application.current.onUpdate.add(counter);

		element.style.width = "333px";

		waitFrames(10, function()
		{
			window.onResize.remove(listener);
			Application.current.onUpdate.remove(counter);
			element.style.width = previous;

			Assert.isTrue(heardAt >= 0, "the resize did not reach the window in 10 frames");
			Assert.isTrue(heardAt <= 2, "the resize reached the window " + heardAt + " frames after the element changed");
			waitFrames(5, function() async.done());
		});
	}

	@Ignored("Waiting on #2132")
	@:timeout(10000)
	public function testGamepadsAreNotPolledBeforeOneConnects(async:Async):Void
	{
		if (js.Syntax.code("!('ongamepadconnected' in window)"))
		{
			trace("This browser has no gamepadconnected event, so gamepads are polled every frame");
			Assert.pass();
			async.done();
			return;
		}

		var polls = spyOnGamepads(null);

		waitFrames(30, function()
		{
			var count = polls();
			Assert.equals(0, count, "the gamepads were asked for " + count + " times in 30 frames with none connected");
			async.done();
		});
	}

	@:timeout(10000)
	public function testAGamepadThatConnectsIsPolled(async:Async):Void
	{
		var pad:Dynamic = {
			index: 0,
			id: "Lime Test Pad",
			connected: true,
			mapping: "",
			axes: [0.0, 0.0],
			buttons: [{pressed: false, value: 0.0}],
			timestamp: 0
		};

		var polls = spyOnGamepads(pad);
		gamepadEvent("gamepadconnected", pad);

		waitFrames(10, function()
		{
			var count = polls();
			gamepadEvent("gamepaddisconnected", pad);
			Assert.isTrue(count >= 5, "a connected gamepad was asked for " + count + " times in 10 frames");
			waitFrames(2, function() async.done());
		});
	}

	// Helpers

	/** The tests start before the application has made its window **/
	private static function withWindow(done:Void->Void):Void
	{
		if (Application.current.window != null) done();
		else haxe.Timer.delay(withWindow.bind(done), 50);
	}

	private static function waitFrames(count:Int, done:Void->Void):Void
	{
		var frames = 0;
		var listener:Int->Void = null;
		listener = function(_:Int)
		{
			if (++frames >= count)
			{
				Application.current.onUpdate.remove(listener);
				done();
			}
		};
		Application.current.onUpdate.add(listener);
	}

	/** Counts reads of the element's client size until the returned function is called, which gives the count **/
	private static function spyOnSize(element:js.html.Element):Void->Int
	{
		var count = 0;
		var counter = function() count++;
		js.Syntax.code("for (var name of ['clientWidth', 'clientHeight']) {
			var original = Object.getOwnPropertyDescriptor(Element.prototype, name);
			(function (original, name) {
				Object.defineProperty({0}, name, { configurable: true, get: function () { {1}(); return original.get.call(this); } });
			})(original, name);
		}", element, counter);

		return function()
		{
			js.Syntax.code("delete {0}.clientWidth; delete {0}.clientHeight;", element);
			return count;
		};
	}

	/** Counts calls to navigator.getGamepads, which gives `pad` alone, or the real list without one **/
	private static function spyOnGamepads(pad:Dynamic):Void->Int
	{
		var count = 0;
		var counter = function() count++;
		js.Syntax.code("var original = navigator.getGamepads;
			navigator.getGamepads = function () { {0}(); return {1} != null ? [{1}] : (original ? original.call(navigator) : []); };", counter, pad);

		return function()
		{
			js.Syntax.code("delete navigator.getGamepads;");
			return count;
		};
	}

	private static function gamepadEvent(type:String, pad:Dynamic):Void
	{
		js.Syntax.code("var event = new Event({0}); Object.defineProperty(event, 'gamepad', { value: {1} }); window.dispatchEvent(event);", type, pad);
	}
	#end
}
