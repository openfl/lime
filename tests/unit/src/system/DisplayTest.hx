package system;

import lime.app.Application;
import lime.system.Display;
import lime.system.System;
import utest.Assert;
import utest.Test;

/**
	Monitors can't be plugged in during a test, so the events SDL sends are
	handed to the application as its event loop would, and are checked to reach
	the right Display events.
**/
class DisplayTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	public function testConnectingADisplayDispatchesIt():Void
	{
		if (System.numDisplays == 0)
		{
			// Without a display, as on the Linux runners, none can be read
			Assert.pass();
			return;
		}

		var connected:Display = null;
		var listener = function(display:Display) connected = display;
		Display.onConnect.add(listener);
		dispatch(2, 0);
		Display.onConnect.remove(listener);

		Assert.notNull(connected, "Display.onConnect was not dispatched");
		if (connected != null) Assert.equals(0, connected.id);
	}

	public function testDisconnectingADisplayDispatchesItsID():Void
	{
		var disconnected = -1;
		var listener = function(id:Int) disconnected = id;
		Display.onDisconnect.add(listener);
		dispatch(3, 1);
		Display.onDisconnect.remove(listener);

		Assert.equals(1, disconnected);
	}

	public function testMovingADisplayDispatchesItsID():Void
	{
		var moved = -1;
		var listener = function(id:Int) moved = id;
		Display.onMove.add(listener);
		dispatch(4, 2);
		Display.onMove.remove(listener);

		Assert.equals(2, moved);
	}

	private static function dispatch(type:Int, display:Int):Void
	{
		// The event as native code fills it in, then the handler it calls
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.orientationEventInfo;
		info.type = cast type;
		info.orientation = 0;
		info.display = display;
		@:privateAccess backend.handleOrientationEvent();
	}
	#end
}
