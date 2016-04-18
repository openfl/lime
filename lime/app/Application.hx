package lime.app;


import lime.graphics.Renderer;
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


/** 
 * The Application class forms the foundation for most Lime projects.
 * It is common to extend this class in a main class. It is then possible
 * to override "on" functions in the class in order to handle standard events
 * that are relevant.
 */
class Application extends Module {
	
	
	public static var current (default, null):Application;
	
	public var config (default, null):Config;
	public var frameRate (get, set):Float;
	public var modules (default, null):Array<IModule>;
	public var preloader (default, null):Preloader;
	
	/**
	 * Update events are dispatched each frame (usually just before rendering)
	 */
	public var onUpdate = new Event<Int->Void> ();
	
	public var renderer (get, null):Renderer;
	public var renderers (default, null):Array<Renderer>;
	public var window (get, null):Window;
	public var windows (default, null):Array<Window>;
	
	@:noCompletion private var backend:ApplicationBackend;
	@:noCompletion private var windowByID:Map<Int, Window>;
	
	
	public function new () {
		
		super ();
		
		if (Application.current == null) {
			
			Application.current = this;
			
		}
		
		modules = new Array ();
		renderers = new Array ();
		windows = new Array ();
		windowByID = new Map ();
		
		backend = new ApplicationBackend (this);
		
		onExit.add (onModuleExit);
		onUpdate.add (update);
		
		Gamepad.onConnect.add (__onGamepadConnect);
		Joystick.onConnect.add (__onJoystickConnect);
		Touch.onStart.add (onTouchStart);
		Touch.onMove.add (onTouchMove);
		Touch.onEnd.add (onTouchEnd);
		
	}
	
	
	/**
	 * Adds a new module to the Application
	 * @param	module	A module to add
	 */
	public function addModule (module:IModule):Void {
		
		modules.push (module);
		
		if (windows.length > 0) {
			
			for (window in windows) {
				
				module.onWindowCreate (window);
				
			}
			
			if (preloader == null || preloader.complete) {
				
				module.onPreloadComplete ();
				
			}
			
		}
		
	}
	
	
	/**
	 * Adds a new Renderer to the Application. By default, this is
	 * called automatically by create()
	 * @param	renderer	A Renderer object to add
	 */
	public function addRenderer (renderer:Renderer):Void {
		
		renderer.onRender.add (render.bind (renderer));
		renderer.onContextLost.add (onRenderContextLost.bind (renderer));
		renderer.onContextRestored.add (onRenderContextRestored.bind (renderer));
		
		renderers.push (renderer);
		
	}
	
	
	/**
	 * Initializes the Application, using the settings defined in
	 * the config instance. By default, this is called automatically
	 * when building the project using Lime's command-line tools
	 * @param	config	A Config object
	 */
	public function create (config:Config):Void {
		
		this.config = config;
		
		backend.create (config);
		
		if (config != null) {
			
			if (Reflect.hasField (config, "fps")) {
				
				frameRate = config.fps;
				
			}
			
			if (Reflect.hasField (config, "windows")) {
				
				for (windowConfig in config.windows) {
					
					var window = new Window (windowConfig);
					createWindow (window);
					
					#if (flash || html5)
					break;
					#end
					
				}
				
			}
			
			if (preloader == null || preloader.complete) {
				
				onPreloadComplete ();
				
			}
			
		}
		
	}
	
	
	/**
	 * Adds a new Window to the Application. By default, this is
	 * called automatically by create()
	 * @param	window	A Window object to add
	 */
	public function createWindow (window:Window):Void {
		
		window.onActivate.add (onWindowActivate.bind (window));
		window.onClose.add (onWindowClose.bind (window));
		window.onCreate.add (onWindowCreate.bind (window));
		window.onDeactivate.add (onWindowDeactivate.bind (window));
		window.onEnter.add (onWindowEnter.bind (window));
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
		window.onResize.add (onWindowResize.bind (window));
		window.onRestore.add (onWindowRestore.bind (window));
		window.onTextEdit.add (onTextEdit.bind (window));
		window.onTextInput.add (onTextInput.bind (window));
		
		if (window.renderer == null) {
			
			var renderer = new Renderer (window);
			addRenderer (renderer);
			
		}
		
		window.create (this);
		windows.push (window);
		windowByID.set (window.id, window);
		
		window.onCreate.dispatch ();
		
	}
	
	
	/**
	 * Execute the Application. On native platforms, this method
	 * blocks until the application is finished running. On other 
	 * platforms, it will return immediately
	 * @return An exit code, 0 if there was no error
	 */
	public function exec ():Int {
		
		Application.current = this;
		
		return backend.exec ();
		
	}
	
	
	public override function onGamepadAxisMove (gamepad:Gamepad, axis:GamepadAxis, value:Float):Void {
		
		for (module in modules) {
			
			module.onGamepadAxisMove (gamepad, axis, value);
			
		}
		
	}
	
	
	public override function onGamepadButtonDown (gamepad:Gamepad, button:GamepadButton):Void {
		
		for (module in modules) {
			
			module.onGamepadButtonDown (gamepad, button);
			
		}
		
	}
	
	
	public override function onGamepadButtonUp (gamepad:Gamepad, button:GamepadButton):Void {
		
		for (module in modules) {
			
			module.onGamepadButtonUp (gamepad, button);
			
		}
		
	}
	
	
	public override function onGamepadConnect (gamepad:Gamepad):Void {
		
		for (module in modules) {
			
			module.onGamepadConnect (gamepad);
			
		}
		
	}
	
	
	public override function onGamepadDisconnect (gamepad:Gamepad):Void {
		
		for (module in modules) {
			
			module.onGamepadDisconnect (gamepad);
			
		}
		
	}
	
	
	public override function onJoystickAxisMove (joystick:Joystick, axis:Int, value:Float):Void {
		
		for (module in modules) {
			
			module.onJoystickAxisMove (joystick, axis, value);
			
		}
		
	}
	
	
	public override function onJoystickButtonDown (joystick:Joystick, button:Int):Void {
		
		for (module in modules) {
			
			module.onJoystickButtonDown (joystick, button);
			
		}
		
	}
	
	
	public override function onJoystickButtonUp (joystick:Joystick, button:Int):Void {
		
		for (module in modules) {
			
			module.onJoystickButtonUp (joystick, button);
			
		}
		
	}
	
	
	public override function onJoystickConnect (joystick:Joystick):Void {
		
		for (module in modules) {
			
			module.onJoystickConnect (joystick);
			
		}
		
	}
	
	
	public override function onJoystickDisconnect (joystick:Joystick):Void {
		
		for (module in modules) {
			
			module.onJoystickDisconnect (joystick);
			
		}
		
	}
	
	
	public override function onJoystickHatMove (joystick:Joystick, hat:Int, position:JoystickHatPosition):Void {
		
		for (module in modules) {
			
			module.onJoystickHatMove (joystick, hat, position);
			
		}
		
	}
	
	
	public override function onJoystickTrackballMove (joystick:Joystick, trackball:Int, value:Float):Void {
		
		for (module in modules) {
			
			module.onJoystickTrackballMove (joystick, trackball, value);
			
		}
		
	}
	
	
	public override function onKeyDown (window:Window, keyCode:KeyCode, modifier:KeyModifier):Void {
		
		for (module in modules) {
			
			module.onKeyDown (window, keyCode, modifier);
			
		}
		
	}
	
	
	public override function onKeyUp (window:Window, keyCode:KeyCode, modifier:KeyModifier):Void {
		
		for (module in modules) {
			
			module.onKeyUp (window, keyCode, modifier);
			
		}
		
	}
	
	
	public override function onModuleExit (code:Int):Void {
		
		for (module in modules) {
			
			module.onModuleExit (code);
			
		}
		
		backend.exit ();
		
	}
	
	
	public override function onMouseDown (window:Window, x:Float, y:Float, button:Int):Void {
		
		for (module in modules) {
			
			module.onMouseDown (window, x, y, button);
			
		}
		
	}
	
	
	public override function onMouseMove (window:Window, x:Float, y:Float):Void {
		
		for (module in modules) {
			
			module.onMouseMove (window, x, y);
			
		}
		
	}
	
	
	public override function onMouseMoveRelative (window:Window, x:Float, y:Float):Void {
		
		for (module in modules) {
			
			module.onMouseMoveRelative (window, x, y);
			
		}
		
	}
	
	
	public override function onMouseUp (window:Window, x:Float, y:Float, button:Int):Void {
		
		for (module in modules) {
			
			module.onMouseUp (window, x, y, button);
			
		}
		
	}
	
	
	public override function onMouseWheel (window:Window, deltaX:Float, deltaY:Float):Void {
		
		for (module in modules) {
			
			module.onMouseWheel (window, deltaX, deltaY);
			
		}
		
	}
	
	
	public override function onPreloadComplete ():Void {
		
		for (module in modules) {
			
			module.onPreloadComplete ();
			
		}
		
	}
	
	
	public override function onPreloadProgress (loaded:Int, total:Int):Void {
		
		for (module in modules) {
			
			module.onPreloadProgress (loaded, total);
			
		}
		
	}
	
	
	public override function onRenderContextLost (renderer:Renderer):Void {
		
		for (module in modules) {
			
			module.onRenderContextLost (renderer);
			
		}
		
	}
	
	
	public override function onRenderContextRestored (renderer:Renderer, context:RenderContext):Void {
		
		for (module in modules) {
			
			module.onRenderContextRestored (renderer, context);
			
		}
		
	}
	
	
	public override function onTextEdit (window:Window, text:String, start:Int, length:Int):Void {
		
		for (module in modules) {
			
			module.onTextEdit (window, text, start, length);
			
		}
		
	}
	
	
	public override function onTextInput (window:Window, text:String):Void {
		
		for (module in modules) {
			
			module.onTextInput (window, text);
			
		}
		
	}
	
	
	public override function onTouchEnd (touch:Touch):Void {
		
		for (module in modules) {
			
			module.onTouchEnd (touch);
			
		}
		
	}
	
	
	public override function onTouchMove (touch:Touch):Void {
		
		for (module in modules) {
			
			module.onTouchMove (touch);
			
		}
		
	}
	
	
	public override function onTouchStart (touch:Touch):Void {
		
		for (module in modules) {
			
			module.onTouchStart (touch);
			
		}
		
	}
	
	
	public override function onWindowActivate (window:Window):Void {
		
		for (module in modules) {
			
			module.onWindowActivate (window);
			
		}
		
	}
	
	
	public override function onWindowClose (window:Window):Void {
		
		for (module in modules) {
			
			module.onWindowClose (window);
			
		}
		
		removeWindow (window);
		
	}
	
	
	public override function onWindowCreate (window:Window):Void {
		
		for (module in modules) {
			
			module.onWindowCreate (window);
			
		}
		
	}
	
	
	public override function onWindowDeactivate (window:Window):Void {
		
		for (module in modules) {
			
			module.onWindowDeactivate (window);
			
		}
		
	}
	
	
	public override function onWindowEnter (window:Window):Void {
		
		for (module in modules) {
			
			module.onWindowEnter (window);
			
		}
		
	}
	
	
	public override function onWindowFocusIn (window:Window):Void {
		
		for (module in modules) {
			
			module.onWindowFocusIn (window);
			
		}
		
	}
	
	
	public override function onWindowFocusOut (window:Window):Void {
		
		for (module in modules) {
			
			module.onWindowFocusOut (window);
			
		}
		
	}
	
	
	public override function onWindowFullscreen (window:Window):Void {
		
		for (module in modules) {
			
			module.onWindowFullscreen (window);
			
		}
		
	}
	
	
	public override function onWindowLeave (window:Window):Void {
		
		for (module in modules) {
			
			module.onWindowLeave (window);
			
		}
		
	}
	
	
	public override function onWindowMinimize (window:Window):Void {
		
		for (module in modules) {
			
			module.onWindowMinimize (window);
			
		}
		
	}
	
	
	public override function onWindowMove (window:Window, x:Float, y:Float):Void {
		
		for (module in modules) {
			
			module.onWindowMove (window, x, y);
			
		}
		
	}
	
	
	public override function onWindowResize (window:Window, width:Int, height:Int):Void {
		
		for (module in modules) {
			
			module.onWindowResize (window, width, height);
			
		}
		
	}
	
	
	public override function onWindowRestore (window:Window):Void {
		
		for (module in modules) {
			
			module.onWindowRestore (window);
			
		}
		
	}
	
	
	/**
	 * Removes a module from the Application
	 * @param	module	A module to remove
	 */
	public function removeModule (module:IModule):Void {
		
		if (module != null) {
			
			module.onModuleExit (0);
			modules.remove (module);
			
		}
		
	}
	
	
	/**
	 * Removes a Renderer from the Application
	 * @param	renderer	A Renderer object to remove
	 */
	public function removeRenderer (renderer:Renderer):Void {
		
		if (renderer != null && renderers.indexOf (renderer) > -1) {
			
			renderers.remove (renderer);
			
		}
		
	}
	
	
	/**
	 * Removes a Window from the Application
	 * @param	window	A Window object to remove
	 */
	private function removeWindow (window:Window):Void {
		
		if (window != null && windowByID.exists (window.id)) {
			
			windows.remove (window);
			windowByID.remove (window.id);
			window.close ();
			
			if (this.window == window) {
				
				this.window = null;
				
			}
			
		}
		
	}
	
	
	public override function render (renderer:Renderer):Void {
		
		for (module in modules) {
			
			module.render (renderer);
			
		}
		
	}
	
	
	private function setPreloader (preloader:Preloader):Void {
		
		if (this.preloader != null) {
			
			this.preloader.onProgress.remove (onPreloadProgress);
			this.preloader.onComplete.remove (onPreloadComplete);
			
		}
		
		this.preloader = preloader;
		
		if (preloader.complete) {
			
			onPreloadComplete ();
			
		} else {
			
			preloader.onProgress.add (onPreloadProgress);
			preloader.onComplete.add (onPreloadComplete);
			
		}
		
	}
	
	
	public override function update (deltaTime:Int):Void {
		
		for (module in modules) {
			
			module.update (deltaTime);
			
		}
		
	}
	
	
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

	public function stopUpdating(): Void{

		#if js
			ApplicationBackend.stopUpdating = true;
		#end
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private inline function get_frameRate ():Float {
		
		return backend.getFrameRate ();
		
	}
	
	
	@:noCompletion private inline function set_frameRate (value:Float):Float {
		
		return backend.setFrameRate (value);
		
	}
	
	
	@:noCompletion private inline function get_renderer ():Renderer {
		
		return renderers[0];
		
	}
	
	
	@:noCompletion private inline function get_window ():Window {
		
		return windows[0];
		
	}
	
	
}


#if flash
@:noCompletion private typedef ApplicationBackend = lime._backend.flash.FlashApplication;
#elseif (js && html5)
@:noCompletion private typedef ApplicationBackend = lime._backend.html5.HTML5Application;
#else
@:noCompletion private typedef ApplicationBackend = lime._backend.native.NativeApplication;
#end