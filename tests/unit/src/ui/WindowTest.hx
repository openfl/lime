package ui;

import lime.app.Application;
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
