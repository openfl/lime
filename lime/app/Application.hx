package lime.app;


import lime.graphics.RenderContext;
import lime.graphics.Renderer;
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
	 * The init() method is called once before the first render()
	 * call. This can be used to do initial set-up for the current
	 * render context
	 * @param	context The current render context
	 */
	public function init (context:RenderContext):Void { }
	
	
	/**
	 * Called when a key down event is fired
	 * @param	keyCode	The code of the key that was pressed
	 * @param	modifier	The modifier of the key that was pressed
	 */
	public function onKeyDown (keyCode:KeyCode, modifier:KeyModifier):Void { }
	
	
	/**
	 * Called when a key up event is fired
	 * @param	keyCode	The code of the key that was released
	 * @param	modifier	The modifier of the key that was released
	 */
	public function onKeyUp (keyCode:KeyCode, modifier:KeyModifier):Void { }
	
	
	/**
	 * Called when a mouse down event is fired
	 * @param	x	The current x coordinate of the mouse
	 * @param	y	The current y coordinate of the mouse
	 * @param	button	The ID of the mouse button that was pressed
	 */
	public function onMouseDown (x:Float, y:Float, button:Int):Void { }
	
	
	/**
	 * Called when a mouse move event is fired
	 * @param	x	The current x coordinate of the mouse
	 * @param	y	The current y coordinate of the mouse
	 * @param	button	The ID of the mouse button that was pressed
	 */
	public function onMouseMove (x:Float, y:Float, button:Int):Void { }
	
	
	/**
	 * Called when a mouse up event is fired
	 * @param	x	The current x coordinate of the mouse
	 * @param	y	The current y coordinate of the mouse
	 * @param	button	The ID of the button that was released
	 */
	public function onMouseUp (x:Float, y:Float, button:Int):Void { }
	
	
	/**
	 * Called when a mouse wheel event is fired
	 * @param	deltaX	The amount of horizontal scrolling (if applicable)
	 * @param	deltaY	The amount of vertical scrolling (if applicable)
	 */
	public function onMouseWheel (deltaX:Float, deltaY:Float):Void { }
	
	
	/**
	 * Called when a render context is lost
	 */
	public function onRenderContextLost ():Void { }
	
	
	/**
	 * Called when a render context is restored
	 * @param	context	The current render context
	 */
	public function onRenderContextRestored (context:RenderContext):Void { }
	
	
	/**
	 * Called when a touch end event is fired
	 * @param	x	The current x coordinate of the touch point
	 * @param	y	The current y coordinate of the touch point
	 * @param	id	The ID of the touch point
	 */
	public function onTouchEnd (x:Float, y:Float, id:Int):Void { }
	
	
	/**
	 * Called when a touch move event is fired
	 * @param	x	The current x coordinate of the touch point
	 * @param	y	The current y coordinate of the touch point
	 * @param	id	The ID of the touch point
	 */
	public function onTouchMove (x:Float, y:Float, id:Int):Void { }
	
	
	/**
	 * Called when a touch start event is fired
	 * @param	x	The current x coordinate of the touch point
	 * @param	y	The current y coordinate of the touch point
	 * @param	id	The ID of the touch point
	 */
	public function onTouchStart (x:Float, y:Float, id:Int):Void { }
	
	
	/**
	 * Called when a window activate event is fired
	 */
	public function onWindowActivate ():Void { }
	
	
	/**
	 * Called when a window close event is fired
	 */
	public function onWindowClose ():Void { }
	
	
	/**
	 * Called when a window deactivate event is fired
	 */
	public function onWindowDeactivate ():Void { }
	
	
	/**
	 * Called when a window focus in event is fired
	 */
	public function onWindowFocusIn ():Void { }
	
	
	/**
	 * Called when a window focus out event is fired
	 */
	public function onWindowFocusOut ():Void { }
	
	
	/**
	 * Called when a window move event is fired
	 * @param	x	The x position of the window
	 * @param	y	The y position of the window
	 */
	public function onWindowMove (x:Float, y:Float):Void { }
	
	
	/**
	 * Called when a window resize event is fired
	 * @param	width	The width of the window
	 * @param	height	The height of the window
	 */
	public function onWindowResize (width:Int, height:Int):Void {}
	
	
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
	
	
	/**
	 * Called when a render event is fired
	 * @param	context	The current render context
	 */
	public function render (context:RenderContext):Void { }
	
	
	/**
	 * Called when an update event is fired
	 * @param	deltaTime	The amount of time in milliseconds that has elapsed since the last update
	 */
	public function update (deltaTime:Int):Void { }
	
	
	
	
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