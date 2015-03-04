package lime.app;


import lime.graphics.Renderer;
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
	
	/**
	 * Update events are dispatched each frame (usually just before rendering)
	 */
	public var onUpdate = new Event<Int->Void> ();
	
	public var renderer (get, null):Renderer;
	public var renderers (default, null):Array<Renderer>;
	public var window (get, null):Window;
	public var windows (default, null):Array<Window>;
	
	@:noCompletion private var backend:ApplicationBackend;
	
	
	public function new () {
		
		super ();
		
		if (Application.current == null) {
			
			Application.current = this;
			
		}
		
		renderers = new Array ();
		windows = new Array ();
		backend = new ApplicationBackend (this);
		
		onUpdate.add (update);
		
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
		
		window.onKeyDown.add (onKeyDown);
		window.onKeyUp.add (onKeyUp);
		window.onMouseDown.add (onMouseDown);
		window.onMouseMove.add (onMouseMove);
		window.onMouseUp.add (onMouseUp);
		window.onMouseWheel.add (onMouseWheel);
		window.onTouchStart.add (onTouchStart);
		window.onTouchMove.add (onTouchMove);
		window.onTouchEnd.add (onTouchEnd);
		window.onWindowActivate.add (onWindowActivate);
		window.onWindowClose.add (onWindowClose);
		window.onWindowDeactivate.add (onWindowDeactivate);
		window.onWindowFocusIn.add (onWindowFocusIn);
		window.onWindowFocusOut.add (onWindowFocusOut);
		window.onWindowMove.add (onWindowMove);
		window.onWindowResize.add (onWindowResize);
		
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
	
	
	/**
	 * Removes a Renderer from the Application
	 * @param	renderer	A Renderer object to add
	 */
	public function removeRenderer (renderer:Renderer):Void {
		
		if (renderer != null && renderers.indexOf (renderer) > -1) {
			
			renderers.remove (renderer);
			
		}
		
	}
	
	
	/**
	 * Removes a Window from the Application
	 * @param	window	A Window object to add
	 */
	public function removeWindow (window:Window):Void {
		
		if (window != null && windows.indexOf (window) > -1) {
			
			window.close ();
			windows.remove (window);
			
		}
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
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