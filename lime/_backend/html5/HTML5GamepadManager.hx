package lime._backend.html5;#if (js && html5)

import js.Browser;
import js.html.GamepadEvent;
import js.html.Navigator;
import lime.ui.Gamepad;
import lime.ui.GamepadButton;



typedef LocalGamepadButton = {
	var pressed: Bool;
	var value: Float;
}

class LocalGamepad{
	public var connected : Bool;
	public var buttons : Array<LocalGamepadButton>;
	public var axes : Array<Float>;
	public var timestamp: Float;
	
	public function new()
	{
		connected = false;
		buttons = new Array<LocalGamepadButton>();
		axes = new Array<Float>();
		timestamp = 0;
	}
	
	public static function fromJSGamepad(gamepad:js.html.Gamepad):LocalGamepad
	{
		var newGamepad = new LocalGamepad();
		newGamepad.timestamp = gamepad.timestamp;
		newGamepad.connected = gamepad.connected;
		
		for (i in 0...gamepad.buttons.length)
		{
			newGamepad.buttons.push(normalizeJSButton(gamepad.buttons[i]));
		}
		
		for (i in 0...gamepad.axes.length)
		{
			newGamepad.axes.push(gamepad.axes[i]);
		}
		
		return newGamepad;
	}
	
	public static function normalizeJSButton(button:Dynamic):LocalGamepadButton
	{
		if (untyped __js__("'pressed' in button")) {
			return { pressed: button.pressed, value: button.value };
		} else {
			return { pressed: button == 1.0, value: button };
		}
	}
}

@:access(lime.ui.Gamepad)
@:access(lime.app.Application)
class HTML5GamepadManager {
	private static inline var epsilon:Float = 0.00002;
	private static var hasGamepadEvents:Bool;
	
	private static var _gamepads:Array<LocalGamepad>;

	public static function init(){
		hasGamepadEvents = untyped __js__("'GamepadEvent' in window");

		_gamepads = new Array<LocalGamepad>();
		
		if (hasGamepadEvents){
			Browser.window.addEventListener ("gamepadconnected", handleGamepadEvent, false);
			Browser.window.addEventListener ("gamepaddisconnected", handleGamepadEvent, false);
		}
	}
	
	public static function update(){
		var gamepads:Array<js.html.Gamepad> = getGamepads();
		
		for (gamepad in gamepads)
		{
			if (gamepad != null) {
				addGamepad(gamepad);
				updateGamepad(gamepad);
			}
		}
	}
	
	private static function updateGamepad(gamepad:js.html.Gamepad):Void
	{
		if (!Gamepad.devices.exists(gamepad.index)) return;
		
		var limeGamepad = Gamepad.devices.get(gamepad.index);
		var localGamepad = _gamepads[gamepad.index];
		
		for (idx in 0...gamepad.buttons.length) {
			if (isButtonPressed(gamepad.buttons[idx])) {
				
				
				if (!localGamepad.buttons[idx].pressed) {
					limeGamepad.onButtonDown.dispatch(idx);
				}
				
			} else {
				
				if (localGamepad.buttons[idx].pressed) {
					limeGamepad.onButtonUp.dispatch(idx);
				}
				
			}
			
			localGamepad.buttons[idx] = LocalGamepad.normalizeJSButton(gamepad.buttons[idx]);
		}
		
		for (idx in 0...gamepad.axes.length) {
			
			if (Math.abs(gamepad.axes[idx] - localGamepad.axes[idx]) > epsilon) {
				limeGamepad.onAxisMove.dispatch(idx, gamepad.axes[idx]);
			}
			
			localGamepad.axes[idx] = gamepad.axes[idx];
		}
	}
	
	private static function isButtonPressed(button:Dynamic):Bool
	{
		if (untyped __js__("'pressed' in button")) {
			return button.pressed;
		} else {
			return button == 1.0;
		}
	}
	
	private static function getButtonValue(button:Dynamic):Bool
	{
		if (untyped __js__("'value' in button")) {
			return button.value;
		} else {
			return button;
		}
	}
	
	//TODO: Normalize buttons on add
	
	
	private static function getGamepads():Array<js.html.Gamepad>
	{
		if (untyped __js__("navigator.getGamepads")) {
			
			return untyped navigator.getGamepads();
			
		} else if (untyped navigator.webkitGetGamepads) {
			
			return untyped navigator.webkitGetGamepads();
			
		} else {
			
			return new Array<js.html.Gamepad>();
			
		}
	}

	private static function handleGamepadEvent( event: GamepadEvent ):Void {

		switch (event.type) {

			case "gamepadconnected":
				addGamepad(event.gamepad);

			case "gamepaddisconnected":
				removeGamepad(event.gamepad);

		}
	}

	private static function addGamepad(gm:js.html.Gamepad):Void
	{
		if (!Gamepad.devices.exists(gm.index)) {

			var gamepad = new Gamepad(gm.index);
			Gamepad.devices.set( gm.index, gamepad);
			Gamepad.onConnect.dispatch (gamepad);
			_gamepads[gm.index] = LocalGamepad.fromJSGamepad(gm);

		}
	}

	private static function removeGamepad(gm:js.html.Gamepad):Void
	{
		var gamepad = Gamepad.devices.get (gm.index);
		if (gamepad != null) gamepad.connected = false;
		Gamepad.devices.remove (gm.index);
		_gamepads[gm.index] = null;
		if (gamepad != null) gamepad.onDisconnect.dispatch();
		
	}
}
#end