package lime.app;


import lime.graphics.RenderContext;
import lime.ui.Gamepad;
import lime.ui.GamepadAxis;
import lime.ui.GamepadButton;
import lime.ui.Joystick;
import lime.ui.JoystickHatPosition;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Touch;
import lime.ui.Window;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class Module implements IModule {
	
	
	/**
	 * Exit events are dispatched when the application is exiting
	 */
	public var onExit = new Event<Int->Void> ();
	
	@:noCompletion private var __application:Application;
	@:noCompletion private var __preloader:Preloader;
	@:noCompletion private var __windows:Array<Window>;
	
	
	public function new () {
		
		__windows = new Array ();
		
	}
	
	
	@:noCompletion public function addWindow (window:Window):Void {
		
		window.onActivate.add (onWindowActivate.bind (window));
		window.onClose.add (__onWindowClose.bind (window), false, -10000);
		window.onContextLost.add (onWindowContextLost.bind (window));
		window.onContextRestored.add (onWindowContextRestored.bind (window));
		window.onCreate.add (onWindowCreate.bind (window));
		window.onDeactivate.add (onWindowDeactivate.bind (window));
		window.onDropFile.add (onWindowDropFile.bind (window));
		window.onEnter.add (onWindowEnter.bind (window));
		window.onExpose.add (onWindowExpose.bind (window));
		window.onFocusIn.add (onWindowFocusIn.bind (window));
		window.onFocusOut.add (onWindowFocusOut.bind (window));
		window.onFullscreen.add (onWindowFullscreen.bind (window));
		window.onKeyDown.add (onKeyDown.bind (window));
		window.onKeyUp.add (onKeyUp.bind (window));
		window.onLeave.add (onWindowLeave.bind (window));
		window.onMinimize.add (onWindowMinimize.bind (window));
		window.onMouseDown.add (onMouseDown.bind (window));
		window.onMouseMove.add (onMouseMove.bind (window));
		window.onMouseMoveRelative.add (onMouseMoveRelative.bind (window));
		window.onMouseUp.add (onMouseUp.bind (window));
		window.onMouseWheel.add (onMouseWheel.bind (window));
		window.onMove.add (onWindowMove.bind (window));
		window.onRender.add (render.bind (window));
		window.onResize.add (onWindowResize.bind (window));
		window.onRestore.add (onWindowRestore.bind (window));
		window.onTextEdit.add (onTextEdit.bind (window));
		window.onTextInput.add (onTextInput.bind (window));
		
		if (window.id > -1) {
			
			onWindowCreate (window);
			
		}
		
		__windows.push (window);
		
	}
	
	
	@:noCompletion public function registerModule (application:Application):Void {
		
		__application = application;
		
		application.onExit.add (onModuleExit, false, 0);
		application.onUpdate.add (update);
		
		for (gamepad in Gamepad.devices) {
			
			__onGamepadConnect (gamepad);
			
		}
		
		Gamepad.onConnect.add (__onGamepadConnect);
		
		for (joystick in Joystick.devices) {
			
			__onJoystickConnect (joystick);
			
		}
		
		Joystick.onConnect.add (__onJoystickConnect);
		
		Touch.onCancel.add (onTouchCancel);
		Touch.onStart.add (onTouchStart);
		Touch.onMove.add (onTouchMove);
		Touch.onEnd.add (onTouchEnd);
		
	}
	
	
	@:noCompletion public function removeWindow (window:Window):Void {
		
		if (window != null && __windows.indexOf (window) > -1) {
			
			// TODO: Remove events
			
			__windows.remove (window);
			
		}
		
	}
	
	
	@:noCompletion public function setPreloader (preloader:Preloader):Void {
		
		if (__preloader != null) {
			
			__preloader.onProgress.remove (onPreloadProgress);
			__preloader.onComplete.remove (onPreloadComplete);
			
		}
		
		__preloader = preloader;
		
		if (preloader == null || preloader.complete) {
			
			onPreloadComplete ();
			
		} else {
			
			preloader.onProgress.add (onPreloadProgress);
			preloader.onComplete.add (onPreloadComplete);
			
		}
		
	}
	
	
	@:noCompletion public function unregisterModule (application:Application):Void {
		
		__application.onExit.remove (onModuleExit);
		__application.onUpdate.remove (update);
		
		Gamepad.onConnect.remove (__onGamepadConnect);
		Joystick.onConnect.remove (__onJoystickConnect);
		Touch.onCancel.remove (onTouchCancel);
		Touch.onStart.remove (onTouchStart);
		Touch.onMove.remove (onTouchMove);
		Touch.onEnd.remove (onTouchEnd);
		
		onModuleExit (0);
		
	}
	
	
	/**
	 * Called when a gamepad axis move event is fired
	 * @param	gamepad	The current gamepad
	 * @param	axis	The axis that was moved
	 * @param	value	The axis value (between 0 and 1)
	 */
	public function onGamepadAxisMove (gamepad:Gamepad, axis:GamepadAxis, value:Float):Void { }
	
	
	/**
	 * Called when a gamepad button down event is fired
	 * @param	gamepad	The current gamepad
	 * @param	button	The button that was pressed
	 */
	public function onGamepadButtonDown (gamepad:Gamepad, button:GamepadButton):Void { }
	
	
	/**
	 * Called when a gamepad button up event is fired
	 * @param	gamepad	The current gamepad
	 * @param	button	The button that was released
	 */
	public function onGamepadButtonUp (gamepad:Gamepad, button:GamepadButton):Void { }
	
	
	/**
	 * Called when a gamepad is connected
	 * @param	gamepad	The gamepad that was connected
	 */
	public function onGamepadConnect (gamepad:Gamepad):Void { }
	
	
	/**
	 * Called when a gamepad is disconnected
	 * @param	gamepad	The gamepad that was disconnected
	 */
	public function onGamepadDisconnect (gamepad:Gamepad):Void { }
	
	
	/**
	 * Called when a joystick axis move event is fired
	 * @param	joystick	The current joystick
	 * @param	axis	The axis that was moved
	 * @param	value	The axis value (between 0 and 1)
	 */
	public function onJoystickAxisMove (joystick:Joystick, axis:Int, value:Float):Void { }
	
	
	/**
	 * Called when a joystick button down event is fired
	 * @param	joystick	The current joystick
	 * @param	button	The button that was pressed
	 */
	public function onJoystickButtonDown (joystick:Joystick, button:Int):Void { }
	
	
	/**
	 * Called when a joystick button up event is fired
	 * @param	joystick	The current joystick
	 * @param	button	The button that was released
	 */
	public function onJoystickButtonUp (joystick:Joystick, button:Int):Void { }
	
	
	/**
	 * Called when a joystick is connected
	 * @param	joystick	The joystick that was connected
	 */
	public function onJoystickConnect (joystick:Joystick):Void { }
	
	
	/**
	 * Called when a joystick is disconnected
	 * @param	joystick	The joystick that was disconnected
	 */
	public function onJoystickDisconnect (joystick:Joystick):Void { }
	
	
	/**
	 * Called when a joystick hat move event is fired
	 * @param	joystick	The current joystick
	 * @param	hat	The hat that was moved
	 * @param	position	The current hat position
	 */
	public function onJoystickHatMove (joystick:Joystick, hat:Int, position:JoystickHatPosition):Void { }
	
	
	/**
	 * Called when a joystick axis move event is fired
	 * @param	joystick	The current joystick
	 * @param	trackball	The trackball that was moved
	 * @param	x	The x movement of the trackball (between 0 and 1)
	 * @param	y	The y movement of the trackball (between 0 and 1)
	 */
	public function onJoystickTrackballMove (joystick:Joystick, trackball:Int, x:Float, y:Float):Void { }
	
	
	/**
	 * Called when a key down event is fired
	 * @param	window	The window dispatching the event
	 * @param	keyCode	The code of the key that was pressed
	 * @param	modifier	The modifier of the key that was pressed
	 */
	public function onKeyDown (window:Window, keyCode:KeyCode, modifier:KeyModifier):Void { }
	
	
	/**
	 * Called when a key up event is fired
	 * @param	window	The window dispatching the event
	 * @param	keyCode	The code of the key that was released
	 * @param	modifier	The modifier of the key that was released
	 */
	public function onKeyUp (window:Window, keyCode:KeyCode, modifier:KeyModifier):Void { }
	
	
	/**
	 * Called when the module is exiting
	 */
	public function onModuleExit (code:Int):Void { }
	
	
	/**
	 * Called when a mouse down event is fired
	 * @param	window	The window dispatching the event
	 * @param	x	The current x coordinate of the mouse
	 * @param	y	The current y coordinate of the mouse
	 * @param	button	The ID of the mouse button that was pressed
	 */
	public function onMouseDown (window:Window, x:Float, y:Float, button:Int):Void { }
	
	
	/**
	 * Called when a mouse move event is fired
	 * @param	window	The window dispatching the event
	 * @param	x	The current x coordinate of the mouse
	 * @param	y	The current y coordinate of the mouse
	 * @param	button	The ID of the mouse button that was pressed
	 */
	public function onMouseMove (window:Window, x:Float, y:Float):Void { }
	
	
	/**
	 * Called when a mouse move relative event is fired
	 * @param	window	The window dispatching the event
	 * @param	x	The x movement of the mouse
	 * @param	y	The y movement of the mouse
	 * @param	button	The ID of the mouse button that was pressed
	 */
	public function onMouseMoveRelative (window:Window, x:Float, y:Float):Void { }
	
	
	/**
	 * Called when a mouse up event is fired
	 * @param	window	The window dispatching the event
	 * @param	x	The current x coordinate of the mouse
	 * @param	y	The current y coordinate of the mouse
	 * @param	button	The ID of the button that was released
	 */
	public function onMouseUp (window:Window, x:Float, y:Float, button:Int):Void { }
	
	
	/**
	 * Called when a mouse wheel event is fired
	 * @param	window	The window dispatching the event
	 * @param	deltaX	The amount of horizontal scrolling (if applicable)
	 * @param	deltaY	The amount of vertical scrolling (if applicable)
	 */
	public function onMouseWheel (window:Window, deltaX:Float, deltaY:Float):Void { }
	
	
	/**
	 * Called when a preload complete event is fired
	 */
	public function onPreloadComplete ():Void { }
	
	
	/**
	 * Called when a preload progress event is fired
	 * @param	loaded	The number of items that are loaded
	 * @param	total	The total number of items will be loaded
	 */
	public function onPreloadProgress (loaded:Int, total:Int):Void { }
	
	
	/**
	 * Called when a text edit event is fired
	 * @param	window	The window dispatching the event
	 * @param	text	The current replacement text
	 * @param	start	The starting index for the edit
	 * @param	length	The length of the edit
	 */
	public function onTextEdit (window:Window, text:String, start:Int, length:Int):Void { }
	
	
	/**
	 * Called when a text input event is fired
	 * @param	window	The window dispatching the event
	 * @param	text	The current input text
	 */
	public function onTextInput (window:Window, text:String):Void { }
	
	
	/**
	 * Called when a touch cancel event is fired
	 * @param	touch	The current touch object
	 */
	public function onTouchCancel (touch:Touch):Void { }
	
	
	/**
	 * Called when a touch end event is fired
	 * @param	touch	The current touch object
	 */
	public function onTouchEnd (touch:Touch):Void { }
	
	
	/**
	 * Called when a touch move event is fired
	 * @param	touch	The current touch object
	 */
	public function onTouchMove (touch:Touch):Void { }
	
	
	/**
	 * Called when a touch start event is fired
	 * @param	touch	The current touch object
	 */
	public function onTouchStart (touch:Touch):Void { }
	
	
	/**
	 * Called when a window activate event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowActivate (window:Window):Void { }
	
	
	/**
	 * Called when a window close event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowClose (window:Window):Void { }
	
	
	/**
	 * Called when a render context is lost
	 * @param	window	The window dispatching the event
	 */
	public function onWindowContextLost (window:Window):Void { }
	
	
	/**
	 * Called when a render context is restored
	 * @param	window	The window dispatching the event
	 */
	public function onWindowContextRestored (window:Window):Void { }
	
	
	/**
	 * Called when a window create event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowCreate (window:Window):Void { }
	
	
	/**
	 * Called when a window deactivate event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowDeactivate (window:Window):Void { }
	
	
	/**
	 * Called when a window drop file event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowDropFile (window:Window, file:String):Void { }
	
	
	/**
	 * Called when a window enter event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowEnter (window:Window):Void { }
	
	
	/**
	 * Called when a window expose event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowExpose (window:Window):Void { }
	
	
	/**
	 * Called when a window focus in event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowFocusIn (window:Window):Void { }
	
	
	/**
	 * Called when a window focus out event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowFocusOut (window:Window):Void { }
	
	
	/**
	 * Called when a window enters fullscreen
	 * @param	window	The window dispatching the event
	 */
	public function onWindowFullscreen (window:Window):Void { }
	
	
	/**
	 * Called when a window leave event is fired
	 * @param	window	The window dispatching the event
	 */
	public function onWindowLeave (window:Window):Void { }
	
	
	/**
	 * Called when a window move event is fired
	 * @param	window	The window dispatching the event
	 * @param	x	The x position of the window in desktop coordinates
	 * @param	y	The y position of the window in desktop coordinates
	 */
	public function onWindowMove (window:Window, x:Float, y:Float):Void { }
	
	
	/**
	 * Called when a window is minimized
	 * @param	window	The window dispatching the event
	 */
	public function onWindowMinimize (window:Window):Void { }
	
	
	/**
	 * Called when a window resize event is fired
	 * @param	window	The window dispatching the event
	 * @param	width	The width of the window
	 * @param	height	The height of the window
	 */
	public function onWindowResize (window:Window, width:Int, height:Int):Void { }
	
	
	/**
	 * Called when a window is restored from being minimized or fullscreen
	 * @param	window	The window dispatching the event
	 */
	public function onWindowRestore (window:Window):Void { }
	
	
	/**
	 * Called when a render event is fired
	 * @param	window	The window dispatching the event
	 */
	public function render (window:Window):Void { }
	
	
	/**
	 * Called when an update event is fired
	 * @param	deltaTime	The amount of time in milliseconds that has elapsed since the last update
	 */
	public function update (deltaTime:Int):Void { }
	
	
	@:noCompletion private function __onGamepadConnect (gamepad:Gamepad):Void {
		
		onGamepadConnect (gamepad);
		
		gamepad.onAxisMove.add (onGamepadAxisMove.bind (gamepad));
		gamepad.onButtonDown.add (onGamepadButtonDown.bind (gamepad));
		gamepad.onButtonUp.add (onGamepadButtonUp.bind (gamepad));
		gamepad.onDisconnect.add (onGamepadDisconnect.bind (gamepad));
		
	}
	
	
	@:noCompletion private function __onJoystickConnect (joystick:Joystick):Void {
		
		onJoystickConnect (joystick);
		
		joystick.onAxisMove.add (onJoystickAxisMove.bind (joystick));
		joystick.onButtonDown.add (onJoystickButtonDown.bind (joystick));
		joystick.onButtonUp.add (onJoystickButtonUp.bind (joystick));
		joystick.onDisconnect.add (onJoystickDisconnect.bind (joystick));
		joystick.onHatMove.add (onJoystickHatMove.bind (joystick));
		joystick.onTrackballMove.add (onJoystickTrackballMove.bind (joystick));
		
	}
	
	
	@:noCompletion private function __onWindowClose (window:Window):Void {
		
		onWindowClose (window);
		
		__windows.remove (window);
		
	}
	
	
}