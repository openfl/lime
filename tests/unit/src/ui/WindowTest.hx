package ui;

import lime.app.Application;
import lime.math.Rectangle;
import lime.ui.Window;
import utest.Assert;
import utest.Test;

/**
	Windows are checked for what the platform made of them, as the attributes
	only say what was asked for.
**/
class WindowTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && (windows || mac || linux) && !rpi)
	public function testTransparentWindowsAreTransparent():Void
	{
		var window = create(true);

		if (window == null)
		{
			if (canCreateWindows()) Assert.fail("a transparent window could not be created");
			return;
		}

		Assert.isTrue(isTransparent(window), "a window created transparent was made opaque");
	}

	public function testWindowsAfterATransparentOneAreOpaque():Void
	{
		// Linux chooses a transparent window's visual through a setting that
		// would otherwise hold for every window created after it
		create(true);
		var second = create(false);

		if (second == null)
		{
			canCreateWindows();
			return;
		}

		Assert.isFalse(isTransparent(second), "a window created after a transparent one was made transparent too");
	}

	public function testFlashing():Void
	{
		var window = create(false);

		if (window == null)
		{
			canCreateWindows();
			return;
		}

		Assert.isTrue(window.flash(BRIEFLY), "the window could not be flashed");
		Assert.isTrue(window.flash(UNTIL_FOCUSED), "the window could not be flashed until focused");
		Assert.isTrue(window.flash(CANCEL), "the window's flashing could not be cancelled");
	}

	public function testMouseRectKeepsTheCursorWhereItIsSet():Void
	{
		var window = create(false);

		if (window == null)
		{
			canCreateWindows();
			return;
		}

		Assert.isNull(window.mouseRect, "a new window kept the cursor to an area");

		window.mouseRect = new Rectangle(4, 8, 20, 24);
		var rect = window.mouseRect;
		Assert.notNull(rect, "the cursor was not kept to the area set");

		if (rect != null)
		{
			Assert.equals("4,8,20,24", [rect.x, rect.y, rect.width, rect.height].join(","));
		}

		window.mouseRect = null;
		Assert.isNull(window.mouseRect, "the cursor was still kept to an area after it was freed");
	}

	public function testKeyboardGrabIsKeptUntilReleased():Void
	{
		var window = create(false);

		if (window == null)
		{
			canCreateWindows();
			return;
		}

		Assert.isFalse(window.keyboardGrab, "a new window grabbed the keyboard");

		// The keys are only taken while the window has the focus, but the grab
		// is kept for when it does
		window.keyboardGrab = true;
		Assert.isTrue(window.keyboardGrab, "the keyboard grab was not kept");

		window.keyboardGrab = false;
		Assert.isFalse(window.keyboardGrab, "the keyboard grab was not released");
	}

	private static function create(transparent:Bool):Window
	{
		// The windows are left open, hidden, as closing the last window of the
		// application ends it, and the tests run before its own window opens
		return Application.current.createWindow({
			width: 64,
			height: 64,
			hidden: true,
			title: "WindowTest",
			transparent: transparent
		});
	}

	private static function canCreateWindows():Bool
	{
		// Without a display, as on the Linux runners, no window can be created
		if (create(false) != null) return true;

		// utest takes a warning as a failure, so the test passes, saying why
		trace("No window can be created here, so windows were not tested");
		Assert.pass();
		return false;
	}

	private static function isTransparent(window:Window):Bool
	{
		return @:privateAccess lime._internal.backend.native.NativeCFFI.lime_window_get_transparent(window.__backend.handle);
	}
	#end
}
