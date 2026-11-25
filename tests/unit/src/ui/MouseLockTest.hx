package ui;

#if (js && html5)
import js.Browser;
import js.html.Element;
import lime.app.Application;
import lime.ui.Window;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	`Window.mouseLock` on HTML5, which is the browser's pointer lock (#1730). Setting it requests
	pointer lock on the window's element and clearing it exits the lock; it reads true while the
	browser has the pointer locked to the element. While it is locked, a mouse event's position stays
	where the lock began and its `movementX` and `movementY` say how far the mouse moved, so
	`onMouseMoveRelative` reports those, in the window's units as positions are, as native targets
	report relative motion.

	A browser only grants pointer lock from a user input handler, so these tests put a stand-in for
	the Pointer Lock API on the window's element and the document, which locks or refuses as a
	browser would, and the real cursor is never captured.
**/
class MouseLockTest extends Test
{
	public function new()
	{
		super();
	}

	#if (js && html5)
	@:timeout(10000)
	public function testMouseLockIsTheBrowsersPointerLock(async:Async):Void
	{
		withWindow(async, function(window)
		{
			var lock = new PointerLockStandIn(window.element, true);

			try
			{
				Assert.isFalse(window.mouseLock, "mouseLock before it was set");

				window.mouseLock = true;
				Assert.equals(1, lock.requests, "requests for pointer lock");
				Assert.isTrue(lock.requestedOn == window.element, "pointer lock was requested on another element");
				Assert.isTrue(window.mouseLock, "mouseLock once the browser has locked the pointer");

				window.mouseLock = false;
				Assert.equals(1, lock.exits, "exits from pointer lock");
				Assert.isFalse(window.mouseLock, "mouseLock once the lock was exited");

				// The browser ends the lock itself when the user presses Escape
				window.mouseLock = true;
				lock.release();
				Assert.isFalse(window.mouseLock, "mouseLock once the browser ended the lock");

				// Another element's lock is not the window's
				lock.lockOther();
				Assert.isFalse(window.mouseLock, "mouseLock while another element has the pointer");
			}
			catch (e:Dynamic)
			{
				Assert.fail("threw " + e);
			}

			lock.restore();
			async.done();
		});
	}

	@:timeout(10000)
	public function testMouseLockStaysOffUntilTheBrowserLocksThePointer(async:Async):Void
	{
		// The browser grants the lock after the request, and only from a user input handler
		withWindow(async, function(window)
		{
			var lock = new PointerLockStandIn(window.element, false);
			var rejections = [];
			var listener = function(event:Dynamic)
			{
				rejections.push(Std.string(event.reason));
				event.preventDefault();
			};
			Browser.window.addEventListener("unhandledrejection", listener);

			try
			{
				window.mouseLock = true;
				Assert.equals(1, lock.requests, "requests for pointer lock");
				Assert.isFalse(window.mouseLock, "mouseLock while the request has not been granted");
			}
			catch (e:Dynamic)
			{
				Assert.fail("threw " + e);
			}

			// The refusal is a rejected promise, which nothing should leave unhandled
			haxe.Timer.delay(function()
			{
				Browser.window.removeEventListener("unhandledrejection", listener);
				lock.restore();

				Assert.isFalse(window.mouseLock, "mouseLock after the request was refused");
				Assert.equals("", rejections.join(", "), "the refused request was reported as an unhandled rejection");
				async.done();
			}, 200);
		});
	}

	@:timeout(10000)
	public function testWhileLockedRelativeMotionIsTheEventsMovement(async:Async):Void
	{
		withWindow(async, function(window)
		{
			var target = moveTarget(window);
			var rect = target.getBoundingClientRect();
			if (hasNoSize(window, rect, async)) return;

			var lock = new PointerLockStandIn(window.element, true);
			var x = Std.int(rect.left) + 10;
			var y = Std.int(rect.top) + 10;
			var heard = [];
			var listener = function(dx:Float, dy:Float) heard.push(pair(dx, dy));

			try
			{
				move(target, x, y, 0, 0);
				window.mouseLock = true;
				window.onMouseMoveRelative.add(listener);

				// The position stays where the lock began
				move(target, x, y, 5, -3);
				move(target, x, y, 2, 0);
				move(target, x, y, 0, 0);
				move(target, x, y, -7, 11);
			}
			catch (e:Dynamic)
			{
				Assert.fail("threw " + e);
			}

			window.onMouseMoveRelative.remove(listener);
			window.mouseLock = false;
			lock.restore();

			var scaleX = window.width / rect.width;
			var scaleY = window.height / rect.height;
			// A move that moved nothing is not a move
			assertHeard([pair(5 * scaleX, -3 * scaleY), pair(2 * scaleX, 0), pair(-7 * scaleX, 11 * scaleY)].join(" | "), heard, "the movements");
			async.done();
		});
	}

	@:timeout(10000)
	public function testWhileLockedMovementIsScaledAsPositionsAre(async:Async):Void
	{
		// Shown at twice its width and its own height, a canvas is half as many window units across
		// each CSS pixel as it is down each one
		withWindow(async, function(window)
		{
			var target = moveTarget(window);
			if (target.tagName.toLowerCase() != "canvas")
			{
				Assert.pass("the window draws into a " + target.tagName + ", which is not scaled");
				async.done();
				return;
			}

			var before = target.getBoundingClientRect();
			if (hasNoSize(window, before, async)) return;

			var lock = new PointerLockStandIn(window.element, true);
			var width = target.style.width;
			var height = target.style.height;
			target.style.width = (before.width * 2) + "px";
			target.style.height = before.height + "px";

			var rect = target.getBoundingClientRect();
			var x = Std.int(rect.left) + 10;
			var y = Std.int(rect.top) + 10;
			var heard = [];
			var positions = [];
			var listener = function(dx:Float, dy:Float) heard.push(pair(dx, dy));
			var positionListener = function(px:Float, py:Float) positions.push(pair(px, py));

			try
			{
				// Unlocked, positions are scaled by the width and the height each
				move(target, x, y, 0, 0);
				window.onMouseMove.add(positionListener);
				move(target, x + 20, y + 20, 0, 0);
				window.onMouseMove.remove(positionListener);

				window.mouseLock = true;
				window.onMouseMoveRelative.add(listener);
				move(target, x, y, 20, 20);
			}
			catch (e:Dynamic)
			{
				Assert.fail("threw " + e);
			}

			window.onMouseMove.remove(positionListener);
			window.onMouseMoveRelative.remove(listener);
			window.mouseLock = false;
			lock.restore();
			target.style.width = width;
			target.style.height = height;

			var scaleX = window.width / rect.width;
			var scaleY = window.height / rect.height;
			assertHeard(pair((x + 20 - rect.left) * scaleX, (y + 20 - rect.top) * scaleY), positions, "the position");
			assertHeard(pair(20 * scaleX, 20 * scaleY), heard, "the movement of 20,20 CSS pixels");
			async.done();
		});
	}

	@:timeout(10000)
	public function testWithoutTheLockRelativeMotionIsTheChangeInPosition(async:Async):Void
	{
		// As before: the event's own movement plays no part
		withWindow(async, function(window)
		{
			var target = moveTarget(window);
			var rect = target.getBoundingClientRect();
			if (hasNoSize(window, rect, async)) return;

			var x = Std.int(rect.left) + 10;
			var y = Std.int(rect.top) + 10;
			var heard = [];
			var listener = function(dx:Float, dy:Float) heard.push(pair(dx, dy));

			try
			{
				move(target, x, y, 0, 0);
				window.onMouseMoveRelative.add(listener);
				move(target, x + 4, y - 3, 100, 100);
				move(target, x + 4, y - 3, 100, 100);
			}
			catch (e:Dynamic)
			{
				Assert.fail("threw " + e);
			}

			window.onMouseMoveRelative.remove(listener);

			var scaleX = window.width / rect.width;
			var scaleY = window.height / rect.height;
			Assert.isFalse(window.mouseLock);
			assertHeard(pair(4 * scaleX, -3 * scaleY), heard, "the change in position");
			async.done();
		});
	}

	/**
		Whether the window has no size, as in a page that is not shown, where a mouse position can't
		be measured. The test then passes, saying so.
	**/
	private static function hasNoSize(window:Window, rect:js.html.DOMRect, async:Async):Bool
	{
		if (window.width > 0 && window.height > 0 && rect.width > 0 && rect.height > 0) return false;

		Assert.pass("the window is " + window.width + "x" + window.height + " here, so mouse positions can't be measured");
		async.done();
		return true;
	}

	private static function assertHeard(expected:String, heard:Array<String>, label:String, ?pos:haxe.PosInfos):Void
	{
		var actual = heard.join(" | ");
		Assert.equals(expected, actual, label + ": expected \"" + expected + "\" but heard \"" + actual + "\"", pos);
	}

	/** Runs `test` once the application has opened its window, which comes after the tests start **/
	private static function withWindow(async:Async, test:Window->Void):Void
	{
		var timer = new haxe.Timer(10);
		var started = false;
		timer.run = function()
		{
			var window = Application.current != null ? Application.current.window : null;
			// A run already queued can come after stop()
			if (started || window == null) return;
			started = true;
			timer.stop();
			test(window);
		};
	}

	/** The element the window draws into, which mouse events reach the window through **/
	private static function moveTarget(window:Window):Element
	{
		var backend = @:privateAccess window.__backend;
		return backend.canvas != null ? cast backend.canvas : (backend.div != null ? cast backend.div : window.element);
	}

	private static function move(target:Element, clientX:Int, clientY:Int, movementX:Int, movementY:Int):Void
	{
		target.dispatchEvent(new js.html.MouseEvent("mousemove", {
			bubbles: true,
			cancelable: true,
			clientX: clientX,
			clientY: clientY,
			movementX: movementX,
			movementY: movementY
		}));
	}

	private static function pair(x:Float, y:Float):String
	{
		return round(x) + "," + round(y);
	}

	private static function round(value:Float):String
	{
		var rounded = Math.round(value * 100) / 100;
		return Std.string(rounded == 0 ? 0 : rounded);
	}
	#end
}

#if (js && html5)
/**
	Stands in for the Pointer Lock API on an element and the document: `requestPointerLock()` locks
	the pointer to the element, or refuses with a rejected promise as a browser does outside a user
	input handler, `document.exitPointerLock()` ends the lock, and `document.pointerLockElement` says
	which element has it. `restore()` puts the browser's own back.
**/
private class PointerLockStandIn
{
	public var exits(default, null) = 0;
	public var requestedOn(default, null):Dynamic = null;
	public var requests(default, null) = 0;

	private var element:Dynamic;
	private var grant:Bool;
	private var locked:Dynamic = null;

	public function new(element:Element, grant:Bool)
	{
		this.element = element;
		this.grant = grant;

		var document:Dynamic = Browser.document;
		js.lib.Object.defineProperty(document, "pointerLockElement", {configurable: true, get: function() return locked});

		var target:Dynamic = element;
		target.requestPointerLock = function(?options:Dynamic)
		{
			requests++;
			requestedOn = js.Lib.nativeThis;

			if (this.grant)
			{
				locked = this.element;
				Browser.document.dispatchEvent(new js.html.Event("pointerlockchange"));
				return js.lib.Promise.resolve(null);
			}

			Browser.document.dispatchEvent(new js.html.Event("pointerlockerror"));
			return js.lib.Promise.reject(new js.html.DOMException("The request was refused", "NotAllowedError"));
		};

		document.exitPointerLock = function()
		{
			exits++;
			release();
		};
	}

	/** The browser ending the lock, as when the user presses Escape **/
	public function release():Void
	{
		locked = null;
		Browser.document.dispatchEvent(new js.html.Event("pointerlockchange"));
	}

	/** The pointer locked to another element of the page **/
	public function lockOther():Void
	{
		locked = Browser.document.body;
		Browser.document.dispatchEvent(new js.html.Event("pointerlockchange"));
	}

	public function restore():Void
	{
		js.Syntax.delete(Browser.document, "pointerLockElement");
		js.Syntax.delete(Browser.document, "exitPointerLock");
		js.Syntax.delete(element, "requestPointerLock");
	}
}
#end
