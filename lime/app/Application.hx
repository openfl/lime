package lime.app;


import lime.graphics.Renderer;
import lime.graphics.RenderContext;
import lime.ui.Gamepad;
import lime.ui.GamepadAxis;
import lime.ui.GamepadButton;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
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
	
	/**
	 * Update events are dispatched each frame (usually just before rendering)
	 */
	public var onUpdate = new Event<Int->Void> ();
	
	public var renderer (get, null):Renderer;
	public var renderers (default, null):Array<Renderer>;
	public var window (get, null):Window;
	public var windows (default, null):Array<Window>;
	
	@:noCompletion private var backend:ApplicationBackend;
	@:noCompletion private var initialized:Bool;
	
	
	public function new () {
		
		super ();
		
		if (Application.current == null) {
			
			Application.current = this;
			
		}
		
		modules = new Array ();
		renderers = new Array ();
		windows = new Array ();
		backend = new ApplicationBackend (this);
		
		onUpdate.add (update);
		
	}
	
	
	/**
	 * Adds a new module to the Application
	 * @param	module	A module to add
	 */
	public function addModule (module:IModule):Void {
		
		modules.push (module);
		
		if (initialized && renderer != null) {
			
			module.init (renderer.context);
			
		}
		
	}
	
	
	/**
	 * Adds a new Renderer to the Application. By default, this is
	 * called automatically by create()
	 * @param	renderer	A Renderer object to add
	 */
	public function addRenderer (renderer:Renderer):Void {
		
		renderer.onRender.add (render);
		renderer.onRenderContextLost.add (onRenderContextLost);
		renderer.onRenderContextRestored.add (onRenderContextRestored);
		
		renderers.push (renderer);
		
	}
	
	
	/**
	 * Adds a new Window to the Application. By default, this is
	 * called automatically by create()
	 * @param	window	A Window object to add
	 */
	public function addWindow (window:Window):Void {
		
		windows.push (window);
		
		window.onGamepadAxisMove.add (onGamepadAxisMove);
		window.onGamepadButtonDown.add (onGamepadButtonDown);
		window.onGamepadButtonUp.add (onGamepadButtonUp);
		window.onGamepadConnect.add (onGamepadConnect);
		window.onGamepadDisconnect.add (onGamepadDisconnect);
		window.onKeyDown.add (onKeyDown);
		window.onKeyUp.add (onKeyUp);
		window.onMouseDown.add (onMouseDown);
		window.onMouseMove.add (onMouseMove);
		window.onMouseMoveRelative.add (onMouseMoveRelative);
		window.onMouseUp.add (onMouseUp);
		window.onMouseWheel.add (onMouseWheel);
		window.onTextEdit.add (onTextEdit);
		window.onTextInput.add (onTextInput);
		window.onTouchStart.add (onTouchStart);
		window.onTouchMove.add (onTouchMove);
		window.onTouchEnd.add (onTouchEnd);
		window.onWindowActivate.add (onWindowActivate);
		window.onWindowClose.add (onWindowClose);
		window.onWindowDeactivate.add (onWindowDeactivate);
		window.onWindowEnter.add (onWindowEnter);
		window.onWindowFocusIn.add (onWindowFocusIn);
		window.onWindowFocusOut.add (onWindowFocusOut);
		window.onWindowFullscreen.add (onWindowFullscreen);
		window.onWindowLeave.add (onWindowLeave);
		window.onWindowMinimize.add (onWindowMinimize);
		window.onWindowMove.add (onWindowMove);
		window.onWindowResize.add (onWindowResize);
		window.onWindowRestore.add (onWindowRestore);
		
		window.create (this);
		
	}
	
	
	/**
	 * Initializes the Application, using the settings defined in
	 * the config instance. By default, this is called automatically
	 * when building the project using Lime's command-line tools
	 * @param	config	A Config object
	 */
	public function create (config:Config):Void {
		
		backend.create (config);
		
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
	
	
	public override function init (context:RenderContext):Void {
		
		for (module in modules) {
			
			module.init (context);
			
		}
		
		initialized = true;
		
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
	
	
	public override function onKeyDown (keyCode:KeyCode, modifier:KeyModifier):Void {
		
		for (module in modules) {
			
			module.onKeyDown (keyCode, modifier);
			
		}
		
	}
	
	
	public override function onKeyUp (keyCode:KeyCode, modifier:KeyModifier):Void {
		
		for (module in modules) {
			
			module.onKeyUp (keyCode, modifier);
			
		}
		
	}
	
	
	public override function onMouseDown (x:Float, y:Float, button:Int):Void {
		
		for (module in modules) {
			
			module.onMouseDown (x, y, button);
			
		}
		
	}
	
	
	public override function onMouseMove (x:Float, y:Float):Void {
		
		for (module in modules) {
			
			module.onMouseMove (x, y);
			
		}
		
	}
	
	
	public override function onMouseMoveRelative (x:Float, y:Float):Void {
		
		for (module in modules) {
			
			module.onMouseMoveRelative (x, y);
			
		}
		
	}
	
	
	public override function onMouseUp (x:Float, y:Float, button:Int):Void {
		
		for (module in modules) {
			
			module.onMouseUp (x, y, button);
			
		}
		
	}
	
	
	public override function onMouseWheel (deltaX:Float, deltaY:Float):Void {
		
		for (module in modules) {
			
			module.onMouseWheel (deltaX, deltaY);
			
		}
		
	}
	
	
	public override function onRenderContextLost ():Void {
		
		for (module in modules) {
			
			module.onRenderContextLost ();
			
		}
		
	}
	
	
	public override function onRenderContextRestored (context:RenderContext):Void {
		
		for (module in modules) {
			
			module.onRenderContextRestored (context);
			
		}
		
	}
	
	
	public override function onTextEdit (text:String, start:Int, length:Int):Void {
		
		for (module in modules) {
			
			module.onTextEdit (text, start, length);
			
		}
		
	}
	
	
	public override function onTextInput (text:String):Void {
		
		for (module in modules) {
			
			module.onTextInput (text);
			
		}
		
	}
	
	
	public override function onTouchEnd (x:Float, y:Float, id:Int):Void {
		
		for (module in modules) {
			
			module.onTouchEnd (x, y, id);
			
		}
		
	}
	
	
	public override function onTouchMove (x:Float, y:Float, id:Int):Void {
		
		for (module in modules) {
			
			module.onTouchMove (x, y, id);
			
		}
		
	}
	
	
	public override function onTouchStart (x:Float, y:Float, id:Int):Void {
		
		for (module in modules) {
			
			module.onTouchStart (x, y, id);
			
		}
		
	}
	
	
	public override function onWindowActivate ():Void {
		
		for (module in modules) {
			
			module.onWindowActivate ();
			
		}
		
	}
	
	
	public override function onWindowClose ():Void {
		
		for (module in modules) {
			
			module.onWindowClose ();
			
		}
		
	}
	
	
	public override function onWindowDeactivate ():Void {
		
		for (module in modules) {
			
			module.onWindowDeactivate ();
			
		}
		
	}
	
	
	public override function onWindowEnter ():Void {
		
		for (module in modules) {
			
			module.onWindowEnter ();
			
		}
		
	}
	
	
	public override function onWindowFocusIn ():Void {
		
		for (module in modules) {
			
			module.onWindowFocusIn ();
			
		}
		
	}
	
	
	public override function onWindowFocusOut ():Void {
		
		for (module in modules) {
			
			module.onWindowFocusOut ();
			
		}
		
	}
	
	
	public override function onWindowFullscreen ():Void {
		
		for (module in modules) {
			
			module.onWindowFullscreen ();
			
		}
		
	}
	
	
	public override function onWindowLeave ():Void {
		
		for (module in modules) {
			
			module.onWindowLeave ();
			
		}
		
	}
	
	
	public override function onWindowMinimize ():Void {
		
		for (module in modules) {
			
			module.onWindowMinimize ();
			
		}
		
	}
	
	
	public override function onWindowMove (x:Float, y:Float):Void {
		
		for (module in modules) {
			
			module.onWindowMove (x, y);
			
		}
		
	}
	
	
	public override function onWindowResize (width:Int, height:Int):Void {
		
		for (module in modules) {
			
			module.onWindowResize (width, height);
			
		}
		
	}
	
	
	public override function onWindowRestore ():Void {
		
		for (module in modules) {
			
			module.onWindowRestore ();
			
		}
		
	}
	
	
	/**
	 * Removes a module from the Application
	 * @param	module	A module to remove
	 */
	public function removeModule (module:IModule):Void {
		
		modules.remove (module);
		
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
	public function removeWindow (window:Window):Void {
		
		if (window != null && windows.indexOf (window) > -1) {
			
			window.close ();
			windows.remove (window);
			
		}
		
	}
	
	
	public override function render (context:RenderContext):Void {
		
		for (module in modules) {
			
			module.render (context);
			
		}
		
	}
	
	
	public override function update (deltaTime:Int):Void {
		
		for (module in modules) {
			
			module.update (deltaTime);
			
		}
		
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