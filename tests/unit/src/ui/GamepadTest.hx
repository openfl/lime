package ui;

import lime._internal.backend.native.NativeCFFI;
import lime.app.Application;
import lime.ui.Gamepad;
import lime.ui.GamepadSensorType;
import lime.ui.GamepadType;
import utest.Assert;
import utest.Test;

/**
	A virtual gamepad stands in for a real one, and keeps the light color and
	rumble it is told to use. Sensors and touchpads can't be made virtual, so
	their events are handed to the application as its event loop would.
**/
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.ui.Gamepad)
class GamepadTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	public function testAVirtualGamepadIsTold():Void
	{
		var id = NativeCFFI.lime_gamepad_attach_virtual();
		Assert.isTrue(id >= 0, "no virtual gamepad could be attached");
		if (id < 0) return;

		Gamepad.__connect(id);
		var gamepad = Gamepad.devices.get(id);

		Assert.equals(GamepadType.VIRTUAL, gamepad.type);

		Assert.isTrue(gamepad.hasLED(), "the gamepad has no light");
		Assert.isTrue(gamepad.setLED(0x336699), "the light could not be set");

		Assert.isTrue(gamepad.hasTriggerRumble(), "the gamepad has no trigger rumble");
		Assert.isTrue(gamepad.rumbleTriggers(0.5, 1, 100), "the triggers could not rumble");
		gamepad.rumble(1, 0.25, 100);

		Assert.isFalse(gamepad.hasSensor(GYROSCOPE), "a virtual gamepad has a gyroscope");
		Assert.isFalse(gamepad.setSensorEnabled(GYROSCOPE, true), "a missing gyroscope was turned on");

		var output:Dynamic = NativeCFFI.lime_gamepad_get_virtual_output(id);
		NativeCFFI.lime_gamepad_detach_virtual(id);
		Gamepad.__disconnect(id);

		Assert.equals(0x336699, output.led);
		Assert.equals(32767, output.leftRumble);
		Assert.equals(65535, output.rightRumble);
		Assert.equals(65535, output.lowRumble);
		Assert.equals(16383, output.highRumble);
	}

	public function testAGamepadThatIsGoneIsToldNothing():Void
	{
		var gamepad = new Gamepad(-2);

		Assert.equals(GamepadType.UNKNOWN, gamepad.type);
		Assert.isFalse(gamepad.hasLED());
		Assert.isFalse(gamepad.setLED(0xFFFFFF));
		Assert.isFalse(gamepad.rumbleTriggers(1, 1, 100));
	}

	public function testSensorReadingsAreDispatched():Void
	{
		var gamepad = connect();
		var readings = "";
		gamepad.onSensorUpdate.add(function(sensor:GamepadSensorType, x, y, z) readings = [sensor, x, y, z].join(","));

		dispatch(5, 0, GamepadSensorType.GYROSCOPE, 0.5, -1.5, 2);
		Gamepad.__disconnect(ID);

		Assert.equals("2,0.5,-1.5,2", readings);
	}

	public function testTouchpadTouchesAreDispatched():Void
	{
		var gamepad = connect();
		var touches = [];
		gamepad.onTouchpadDown.add(function(finger, x, y) touches.push("down " + [finger, x, y].join(",")));
		gamepad.onTouchpadMove.add(function(finger, x, y) touches.push("move " + [finger, x, y].join(",")));
		gamepad.onTouchpadUp.add(function(finger, x, y) touches.push("up " + [finger, x, y].join(",")));

		dispatch(6, 1, 0, 0.25, 0.5, 1);
		dispatch(7, 1, 0, 0.5, 0.5, 1);
		dispatch(8, 1, 0, 0.75, 0.5, 0);
		Gamepad.__disconnect(ID);

		Assert.equals("down 1,0.25,0.5|move 1,0.5,0.5|up 1,0.75,0.5", touches.join("|"));
	}

	private static inline var ID = 1000;

	private static function connect():Gamepad
	{
		Gamepad.__connect(ID);
		return Gamepad.devices.get(ID);
	}

	private static function dispatch(type:Int, button:Int, axis:Int, x:Float, y:Float, z:Float):Void
	{
		// The event as native code fills it in, then the handler it calls
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.gamepadEventInfo;
		info.type = cast type;
		info.id = ID;
		info.button = button;
		info.axis = axis;
		info.x = x;
		info.y = y;
		info.z = z;
		@:privateAccess backend.handleGamepadEvent();
	}
	#end
}
