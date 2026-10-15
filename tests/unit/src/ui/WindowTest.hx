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
		var transparent = isTransparent(window);

		Assert.isTrue(transparent, "a window created transparent was made opaque");
	}

	public function testWindowsAfterATransparentOneAreOpaque():Void
	{
		// Linux chooses a transparent window's visual through a setting that
		// would otherwise hold for every window created after it
		create(true);
		var second = create(false);
		var transparent = isTransparent(second);

		Assert.isFalse(transparent, "a window created after a transparent one was made transparent too");
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

	private static function isTransparent(window:Window):Bool
	{
		return @:privateAccess lime._internal.backend.native.NativeCFFI.lime_window_get_transparent(window.__backend.handle);
	}
	#end
}
