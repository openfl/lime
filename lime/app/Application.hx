package lime.app;


import lime.graphics.Renderer;
import lime.graphics.RenderContext;
import lime.system.System;
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
	public var preloader (get, null):Preloader;
	
	/**
	 * Update events are dispatched each frame (usually just before rendering)
	 */
	public var onUpdate = new Event<Int->Void> ();
	
	public var renderer (get, null):Renderer;
	public var renderers (get, null):Array<Renderer>;
	public var window (get, null):Window;
	public var windows (get, null):Array<Window>;
	
	@:noCompletion private var backend:ApplicationBackend;
	@:noCompletion private var windowByID:Map<Int, Window>;
	
	
	public function new () {
		
		super ();
		
		if (Application.current == null) {
			
			Application.current = this;
			
		}
		
		modules = new Array ();
		windowByID = new Map ();
		
		backend = new ApplicationBackend (this);
		
		registerModule (this);
		
	}
	
	
	/**
	 * Adds a new module to the Application
	 * @param	module	A module to add
	 */
	public function addModule (module:IModule):Void {
		
		module.registerModule (this);
		modules.push (module);
		
		if (__renderers.length > 0) {
			
			for (renderer in __renderers) {
				
				module.addRenderer (renderer);
				
			}
			
		}
		
		if (__windows.length > 0) {
			
			for (window in __windows) {
				
				module.addWindow (window);
				
			}
			
		}
		
		module.setPreloader (__preloader);
		
	}
	
	
	/**
	 * Adds a new Renderer to the Application. By default, this is
	 * called automatically by create()
	 * @param	renderer	A Renderer object to add
	 */
	public override function addRenderer (renderer:Renderer):Void {
		
		super.addRenderer (renderer);
		
		for (module in modules) {
			
			module.addRenderer (renderer);
			
		}
		
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
			
			if (__preloader == null || __preloader.complete) {
				
				setPreloader (__preloader);
				
				for (module in modules) {
					
					setPreloader (__preloader);
					
				}
				
			}
			
		}
		
	}
	
	
	/**
	 * Adds a new Window to the Application. By default, this is
	 * called automatically by create()
	 * @param	window	A Window object to add
	 */
	public function createWindow (window:Window):Void {
		
		super.addWindow (window);
		
		for (module in modules) {
			
			module.addWindow (window);
			
		}
		
		if (window.renderer == null) {
			
			var renderer = new Renderer (window);
			addRenderer (renderer);
			
		}
		
		window.create (this);
		//__windows.push (window);
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
	
	
	public override function onModuleExit (code:Int):Void {
		
		backend.exit ();
		
	}
	
	
	public override function onWindowClose (window:Window):Void {
		
		removeWindow (window);
		
	}
	
	
	/**
	 * Removes a module from the Application
	 * @param	module	A module to remove
	 */
	public function removeModule (module:IModule):Void {
		
		if (module != null) {
			
			module.unregisterModule (this);
			modules.remove (module);
			
		}
		
	}
	
	
	@:noCompletion public override function removeWindow (window:Window):Void {
		
		if (window != null && windowByID.exists (window.id)) {
			
			__windows.remove (window);
			windowByID.remove (window.id);
			window.close ();
			
			if (window.renderer != null) {
				
				removeRenderer (window.renderer);
				
			}
			
			if (this.window == window) {
				
				this.window = null;
				
			}
			
			if (__windows.length == 0) {
				
				System.exit (0);
				
			}
			
		}
		
	}
	
	
	@:noCompletion public override function setPreloader (preloader:Preloader):Void {
		
		super.setPreloader (preloader);
		
		for (module in modules) {
			
			module.setPreloader (preloader);
			
		}
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private inline function get_frameRate ():Float {
		
		return backend.getFrameRate ();
		
	}
	
	
	@:noCompletion private inline function set_frameRate (value:Float):Float {
		
		return backend.setFrameRate (value);
		
	}
	
	
	@:noCompletion private inline function get_preloader ():Preloader {
		
		return __preloader;
		
	}
	
	
	@:noCompletion private inline function get_renderer ():Renderer {
		
		return __renderers[0];
		
	}
	
	
	@:noCompletion private inline function get_renderers ():Array<Renderer> {
		
		return __renderers;
		
	}
	
	
	@:noCompletion private inline function get_window ():Window {
		
		return __windows[0];
		
	}
	
	
	@:noCompletion private inline function get_windows ():Array<Window> {
		
		return __windows;
		
	}
	
	
}


#if flash
@:noCompletion private typedef ApplicationBackend = lime._backend.flash.FlashApplication;
#elseif (js && html5)
@:noCompletion private typedef ApplicationBackend = lime._backend.html5.HTML5Application;
#else
@:noCompletion private typedef ApplicationBackend = lime._backend.native.NativeApplication;
#end