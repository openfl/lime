package ui;

import lime.app.Application;
import lime.math.Rectangle;
import lime.ui.Window;
import lime.ui.WindowAppearance;
import lime.ui.WindowHandleType;
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
	public function testAppearancePreferenceAndInvalidValues():Void
	{
		var window = create(false);
		if (window == null) { canCreateWindows(); return; }
		Assert.equals(WindowAppearance.System, window.appearance);
		window.appearance = WindowAppearance.Dark;
		Assert.equals(WindowAppearance.Dark, window.appearance);
		var applied = window.effectiveAppearance;
		window.appearance = cast "invalid";
		Assert.equals(WindowAppearance.Dark, window.appearance);
		Assert.equals(applied, window.effectiveAppearance);
		window.appearance = null;
		Assert.equals(WindowAppearance.Dark, window.appearance);
		window.appearance = WindowAppearance.System;
		Assert.equals(WindowAppearance.System, window.appearance);
	}

	public function testAppearanceChangesArePerWindow():Void
	{
		var dark = create(false), light = create(false);
		if (dark == null || light == null) { canCreateWindows(); return; }
		dark.appearance = WindowAppearance.Dark;
		light.appearance = WindowAppearance.Light;
		Assert.equals(WindowAppearance.Dark, dark.appearance);
		Assert.equals(WindowAppearance.Light, light.appearance);
		// Unsupported decorations retain the preference and report System.
		if (dark.effectiveAppearance == WindowAppearance.System || light.effectiveAppearance == WindowAppearance.System) {
			Assert.pass();
			return;
		}
		Assert.equals(WindowAppearance.Dark, dark.effectiveAppearance);
		Assert.equals(WindowAppearance.Light, light.effectiveAppearance);
		dark.appearance = WindowAppearance.Light;
		Assert.equals(WindowAppearance.Light, dark.effectiveAppearance);
		Assert.equals(WindowAppearance.Light, light.effectiveAppearance);
		dark.appearance = WindowAppearance.System;
		Assert.equals(WindowAppearance.Light, light.effectiveAppearance);
	}

	public function testAppearanceCreationAttribute():Void
	{
		var window = Application.current.createWindow({width:64, height:64, hidden:true, appearance:WindowAppearance.Dark});
		if (window == null) { canCreateWindows(); return; }
		Assert.equals(WindowAppearance.Dark, window.appearance);
		if (window.effectiveAppearance != WindowAppearance.System)
			Assert.equals(WindowAppearance.Dark, window.effectiveAppearance);
	}

	public function testAlwaysOnTopCreationAttribute():Void
	{
		var window = Application.current.createWindow({width:64, height:64, hidden:true, alwaysOnTop:true});
		if (window == null) { canCreateWindows(); return; }
		Assert.isTrue(window.alwaysOnTop);
	}

	public function testTransparentWindowsAreTransparent():Void
	{
		var window = create(true);

		if (window == null)
		{
			if (canCreateWindows()) Assert.fail("a transparent window could not be created");
			return;
		}

		Assert.isTrue(isTransparent(window), "a window created transparent was made opaque");
		Assert.equals(isTransparent(window), window.transparent);
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

	public function testEachSizeLimitSetsOnlyItself():Void
	{
		var window = create(false);

		if (window == null)
		{
			canCreateWindows();
			return;
		}

		window.minWidth = 40;
		window.minHeight = 30;
		window.maxWidth = 800;
		window.maxHeight = 600;

		Assert.equals("40,30,800,600", [window.minWidth, window.minHeight, window.maxWidth, window.maxHeight].join(","));
	}

	public function testTheFrameRateOutlastsOtherFrameSettings():Void
	{
		// The first window created becomes the application's own
		if (create(false) == null)
		{
			canCreateWindows();
			return;
		}

		var application = Application.current;
		var window = application.window;
		var rate = window.frameRate;
		window.frameRate = 30;

		// Each of these applies every frame setting again, from the rate the application keeps
		application.vsyncMode = application.vsyncMode;
		application.frameProfile = application.frameProfile;

		Assert.equals(30.0, window.frameRate);
		window.frameRate = rate;
	}

	public function testAWindowCanBeClosedWhileItRenders():Void
	{
		// Closing the last window of the application ends it, so another stays open
		if (create(false) == null)
		{
			canCreateWindows();
			return;
		}

		var window = create(false);
		window.onRender.add(function(_) window.close());

		var backend = @:privateAccess Application.current.__backend;
		@:privateAccess backend.renderEventInfo.type = RENDER;
		@:privateAccess backend.handleRenderEvent();

		Assert.isNull(@:privateAccess window.__backend.handle, "the window was not closed");
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

	public function testNativeHandleIsTheSystemsOwnWindow():Void
	{
		var first = create(false), second = create(false);
		if (first == null || second == null) { canCreateWindows(); return; }

		var handle = first.nativeHandle;
		Assert.notNull(handle);
		Assert.equals(#if windows WindowHandleType.WINDOWS #elseif mac WindowHandleType.COCOA #else WindowHandleType.X11 #end, handle.type);
		Assert.isTrue(handle.window != 0);
		Assert.equals(#if linux true #else false #end, handle.display != 0);

		// The same window each time, and each window its own
		Assert.isTrue(handle.window == first.nativeHandle.window);
		Assert.isTrue(handle.window != second.nativeHandle.window);

		first.close();
		Assert.isNull(first.nativeHandle);
	}

	public function testPreciseMouseWheelGivesFractionsOfAStep():Void
	{
		var window = create(false);

		if (window == null)
		{
			canCreateWindows();
			return;
		}

		var deltas = [];
		window.onMouseWheel.add(function(deltaX, deltaY, mode) deltas.push(deltaX + "," + deltaY));

		// A touchpad scrolls a quarter of a step at a time, which SDL adds up into
		// a whole one
		wheel(window, 0, -1, 0, -0.25);
		window.preciseMouseWheel = true;
		wheel(window, 0, -1, 0, -0.25);

		Assert.equals("0,-1|0,-0.25", deltas.join("|"));
	}

	private static function wheel(window:Window, x:Float, y:Float, preciseX:Float, preciseY:Float):Void
	{
		// The event as native code fills it in, then the handler it calls
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.mouseEventInfo;
		info.type = cast 3;
		info.windowID = window.id;
		info.x = x;
		info.y = y;
		info.movementX = preciseX;
		info.movementY = preciseY;
		@:privateAccess backend.handleMouseEvent();
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
