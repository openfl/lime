package lime.app;


import lime.graphics.RenderContext;
import lime.graphics.Renderer;
import lime.ui.Gamepad;
import lime.ui.GamepadAxis;
import lime.ui.GamepadButton;
import lime.ui.Joystick;
import lime.ui.JoystickHatPosition;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Touch;
import lime.ui.Window;


interface IModule {
	
	
	/**
	 * Called when a gamepad axis move event is fired
	 * @param	gamepad	The current gamepad
	 * @param	axis	The axis that was moved
	 * @param	value	The axis value (between 0 and 1)
	 */
	public function onGamepadAxisMove (gamepad:Gamepad, axis:GamepadAxis, value:Float):Void;
	
	
	/**
	 * Called when a gamepad button down event is fired
	 * @param	gamepad	The current gamepad
	 * @param	button	The button that was pressed
	 */
	public function onGamepadButtonDown (gamepad:Gamepad, button:GamepadButton):Void;
	
	
	/**
	 * Called when a gamepad button up event is fired
	 * @param	gamepad	The current gamepad
	 * @param	button	The button that was released
	 */
	public function onGamepadButtonUp (gamepad:Gamepad, button:GamepadButton):Void;
	
	
	/**
	 * Called when a gamepad is connected
	 * @param	gamepad	The gamepad that was connected
	 */
	public function onGamepadConnect (gamepad:Gamepad):Void;
	
	
	/**
	 * Called when a gamepad is disconnected
	 * @param	gamepad	The gamepad that was disconnected
	 */
	public function onGamepadDisconnect (gamepad:Gamepad):Void;
	
	
	/**
	 * Called when a joystick axis move event is fired
	 * @param	joystick	The current joystick
	 * @param	axis	The axis that was moved
	 * @param	value	The axis value (between 0 and 1)
	 */
	public function onJoystickAxisMove (joystick:Joystick, axis:Int, value:Float):Void;
	
	
	/**
	 * Called when a joystick button down event is fired
	 * @param	joystick	The current joystick
	 * @param	button	The button that was pressed
	 */
	public function onJoystickButtonDown (joystick:Joystick, button:Int):Void;
	
	
	/**
	 * Called when a joystick button up event is fired
	 * @param	joystick	The current joystick
	 * @param	button	The button that was released
	 */
	public function onJoystickButtonUp (joystick:Joystick, button:Int):Void;
	
	
	/**
	 * Called when a joystick is connected
	 * @param	joystick	The joystick that was connected
	 */
	public function onJoystickConnect (joystick:Joystick):Void;
	
	
	/**
	 * Called when a joystick is disconnected
	 * @param	joystick	The joystick that was disconnected
	 */
	public function onJoystickDisconnect (joystick:Joystick):Void;
	
	
	/**
	 * Called when a joystick hat move event is fired
	 * @param	joystick	The current joystick
	 * @param	hat	The hat that was moved
	 * @param	position	The current hat position
	 */
	public function onJoystickHatMove (joystick:Joystick, hat:Int, position:JoystickHatPosition):Void;
	
	
	/**
	 * Called when a joystick axis move event is fired
	 * @param	joystick	The current joystick
	 * @param	trackball	The trackball that was moved
	 * @param	value	The trackball value (between 0 and 1)
	 */
	public function onJoystickTrackballMove (joystick:Joystick, trackball:Int, value:Float):Void;
	
	
	/**
	 * Called when a key down event is fired
	 * @param	window	The window dispatching the event
	 * @param	keyCode	The code of the key that was pressed
	 * @param	modifier	The modifier of the key that was pressed
	 */
	public function onKeyDown (window:Window, keyCode:KeyCode, modifier:KeyModifier):Void;
	
	
	/**
	 * Called when a key up event is fired
	 * @param	window	The window dispatching the event
	 * @param	keyCode	The code of the key that was released
	 * @param	modifier	The modifier of the key that was released
	 */
	public function onKeyUp (window:Window, keyCode:KeyCode, modifier:KeyModifier):Void;
	
	
	/**
	 * Called when the module is exiting
	 */
	public function onModuleExit (code:Int):Void;
	
	
	/**
	 * Called when a mouse down event is fired
	 * @param	window	The window dispatching the event
	 * @param	x	The current x coordinate of the mouse
	 * @param	y	The current y coordinate of the mouse
	 * @param	button	The ID of the mouse button that was pressed
	 */
	public function onMouseDown (window:Window, x:Float, y:Float, button:Int):Void;
	
	
	/**
	 * Called when a mouse move event is fired
	 * @param	window	The window dispatching the event
	 * @param	x	The current x coordinate of the mouse
	 * @param	y	The current y coordinate of the mouse
	 * @param	button	The ID of the mouse button that was pressed
	 */
	public function onMouseMove (window:Window, x:Float, y:Float):Void;
	
	
	/**
	 * Called when a mouse move relative event is fired
	 * @param	window	The window dispatching the event
	 * @param	x	The x movement of the mouse
	 * @param	y	The y movement of the mouse
	 * @param	button	The ID of the mouse button that was pressed
	 */
	public function onMouseMoveRelative (window:Window, x:Float, y:Float):Void;
	
	
	/**
	 * Called when a mouse up event is fired
	 * @param	window	The window dispatching the event
	 * @param	x	The current x coordinate of the mouse
	 * @param	y	The current y coordinate of the mouse
	 * @param	button	The ID of the button that was released
	 */
	public function onMouseUp (window:Window, x:Float, y:Float, button:Int):Void;
	
	
	/**
	 * Called when a mouse wheel event is fired
	 * @param	window	The window dispatching the event
	 * @param	deltaX	The amount of horizontal scrolling (if applicable)
	 * @param	deltaY	The amount of vertical scrolling (if applicable)
	 */
	public function onMouseWheel (window:Window, deltaX:Float, deltaY:Float):Void;
	
	
	/**
	 * Called when a preload complete event is fired
	 */
	public function onPreloadComplete ():Void;
	
	
	/**
	 * Called when a preload progress event is fired
	 * @param	loaded	The number of items that are loaded
	 * @param	total	The total number of items will be loaded
	 */
	public function onPreloadProgress (loaded:Int, total:Int):Void;
	
	
	/**
	 * Called when a render context is lost
	 * @param	renderer	The renderer dispatching the event
	 */
	public function onRenderContextLost (renderer:Renderer):Void;
	
	
	/**
	 * Called when a render context is restored
	 * @param	renderer	The renderer dispatching the event
	 * @param	context	The current render context
	 */
	public function onRenderContextRestored (renderer:Renderer, context:RenderContext):Void;
	
	
	/**
	 * Called when a text edit event is fired
	 * @param	window	The window dispatching the event
	 * @param	text	The current replacement text
	 * @param	start	The starting index for the edit
	 * @param	length	The length of the edit
	 */
	public function onTextEdit (window:Window, text:String, start:Int, length:Int):Void;
	
	
	/**
	 * Called when a text input event is fired
	 * @param	window	The window dispatching the event
	 * @param	text	The current input text
	 */
	public function onTextInput (window:Window, text:String):Void;
	
	
	/**
	 * Called when a touch end event is fired
	 * @param	touch	The current touch object
	 */
	public function onTouchEnd (touch:Touch):Void;
	
	
	/**
	 * Called when a touch move event is fired
	 * @param	touch	The current touch object
	 */
	public function onTouchMove (touch:Touch):Void;
	
	
	/**
	 * Called when a touch start event is fired
	 * @param	touch	The current touch object
	 */
	public function onTouchStart (touch:Touch):Void;
	
	
	/**
	 * Called when a window activate event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowActivate (window:Window):Void;
	
	
	/**
	 * Called when a window close event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowClose (window:Window):Void;
	
	
	/**
	 * Called when a window create event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowCreate (window:Window):Void;
	
	
	/**
	 * Called when a window deactivate event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowDeactivate (window:Window):Void;
	
	
	/**
	 * Called when a window enter event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowEnter (window:Window):Void;
	
	
	/**
	 * Called when a window focus in event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowFocusIn (window:Window):Void;
	
	
	/**
	 * Called when a window focus out event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowFocusOut (window:Window):Void;
	
	
	/**
	 * Called when a window enters fullscreen
	 * @param	window	The window dispatching the event
	 */
	public function onWindowFullscreen (window:Window):Void;
	
	
	/**
	 * Called when a window leave event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowLeave (window:Window):Void;
	
	
	/**
	 * Called when a window move event is fired
	 * @param	window	The window dispatching the event
	 * @param	x	The x position of the window in desktop coordinates
	 * @param	y	The y position of the window in desktop coordinates
	 */
	public function onWindowMove (window:Window, x:Float, y:Float):Void;
	
	
	/**
	 * Called when a window is minimized
	 * @param	window	The window dispatching the event
	 */
	public function onWindowMinimize (window:Window):Void;
	
	
	/**
	 * Called when a window resize event is fired
	 * @param	window	The window dispatching the event
	 * @param	width	The width of the window
	 * @param	height	The height of the window
	 */
	public function onWindowResize (window:Window, width:Int, height:Int):Void;
	
	
	/**
	 * Called when a window is restored from being minimized or fullscreen
	 * @param	window	The window dispatching the event
	 */
	public function onWindowRestore (window:Window):Void;
	
	
	/**
	 * Called when a render event is fired
	 * @param	renderer	The renderer dispatching the event
	 */
	public function render (renderer:Renderer):Void;
	
	
	/**
	 * Called when an update event is fired
	 * @param	deltaTime	The amount of time in milliseconds that has elapsed since the last update
	 */
	public function update (deltaTime:Int):Void;
	
	
}