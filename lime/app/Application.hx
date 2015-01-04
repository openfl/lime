package lime.app;


import lime.audio.AudioManager;
import lime.graphics.*;
import lime.system.*;
import lime.ui.*;

#if (js && html5)
import js.Browser;
#elseif flash
import flash.Lib;
#elseif java
import org.lwjgl.opengl.GL11;
import org.lwjgl.system.glfw.GLFW;
#elseif windows
import sys.FileSystem;
#end


/**
 * The Application class forms the foundation for most Lime projects.
 * It is common to extend this class in a main class. It is then possible
 * to override "on" functions in the class in order to handle standard events
 * that are relevant.
 */
class Application extends Module {
	
	
	/**
	 * Update events are dispatched each frame (usually just before rendering)
	 */
	public static var onUpdate = new Event<Int->Void> ();
	
	private static var __eventInfo = new UpdateEventInfo ();
	private static var __initialized:Bool;
	private static var __instance:Application;
	private static var __registered:Bool;
	
	public var config (default, null):Config;
	public var window (get, null):Window;
	public var windows (default, null):Array<Window>;
	
	@:noCompletion private var __handle:Dynamic;
	
	
	public function new () {
		
		super ();
		
		__instance = this;
		
		windows = new Array ();
		
		if (!__registered) {
			
			__registered = true;
			
			AudioManager.init ();
			
			#if (cpp || neko || nodejs)
				
				lime_update_event_manager_register (__dispatch, __eventInfo);
				
			#end
			
		}
		
	}
	
	
	/**
	 * Adds a new Window to the Application. By default, this is
	 * called automatically by create()
	 * @param	window	A Window object to add
	 */
	public function addWindow (window:Window):Void {
		
		windows.push (window);
		window.create (this);
		
	}
	
	
	/**
	 * Initializes the Application, using the settings defined in
	 * the config instance. By default, this is called automatically
	 * when building the project using Lime's command-line tools
	 * @param	config	A Config object
	 */
	public function create (config:Config):Void {
		
		this.config = config;
		
		#if (cpp || neko || nodejs)
			
			__handle = lime_application_create (null);
			
		#elseif java
			
			GLFW.glfwInit ();
			
		#end
		
		KeyEventManager.create ();
		MouseEventManager.create ();
		TouchEventManager.create ();
		
		KeyEventManager.onKeyDown.add (onKeyDown);
		KeyEventManager.onKeyUp.add (onKeyUp);
		
		MouseEventManager.onMouseDown.add (onMouseDown);
		MouseEventManager.onMouseMove.add (onMouseMove);
		MouseEventManager.onMouseUp.add (onMouseUp);
		MouseEventManager.onMouseWheel.add (onMouseWheel);
		
		TouchEventManager.onTouchStart.add (onTouchStart);
		TouchEventManager.onTouchMove.add (onTouchMove);
		TouchEventManager.onTouchEnd.add (onTouchEnd);
		
		Renderer.onRenderContextLost.add (onRenderContextLost);
		Renderer.onRenderContextRestored.add (onRenderContextRestored);
		
		Window.onWindowActivate.add (onWindowActivate);
		Window.onWindowClose.add (onWindowClose);
		Window.onWindowDeactivate.add (onWindowDeactivate);
		Window.onWindowFocusIn.add (onWindowFocusIn);
		Window.onWindowFocusOut.add (onWindowFocusOut);
		Window.onWindowMove.add (onWindowMove);
		Window.onWindowResize.add (onWindowResize);
		
		var window = new Window (config);
		var renderer = new Renderer (window);
		
		window.width = config.width;
		window.height = config.height;
		
		#if (js && html5)
			
			window.element = config.element;
			
		#end
		
		addWindow (window);
		
		#if windows
			
			if (FileSystem.exists ("icon.png")) {
				
				var image = Image.fromFile ("icon.png");
				window.setIcon (image);
				
			}
			
		#end
		
	}
	
	
	/**
	 * Execute the Application. On native platforms, this method
	 * blocks until the application is finished running. On other 
	 * platforms, it will return immediately
	 * @return An exit code, 0 if there was no error
	 */
	public function exec ():Int {
		
		#if nodejs
			
			lime_application_init (__handle);
			
			var prevTime = untyped __js__ ('Date.now ()');
			var eventLoop = function () {
				
				var active = lime_application_update (__handle);
				
				if (!active) {
					
					var result = lime_application_quit (__handle);
					__cleanup ();
					Sys.exit (result);
					
				}
				
				var time =  untyped __js__ ('Date.now ()');
				if (time - prevTime <= 16) {
					
					untyped setTimeout (eventLoop, 0);
					
				}
				else {
					
					untyped setImmediate (eventLoop);
					
				}
				
				prevTime = time;
				
			}
			
			untyped setImmediate (eventLoop);
			
		#elseif (cpp || neko)
			
			lime_application_init (__handle);
			
			while (lime_application_update (__handle)) {}
			
			var result = lime_application_quit (__handle);
			__cleanup ();
			
			return result;
			
		#elseif (js && html5)
			
			untyped __js__ ("
				var lastTime = 0;
				var vendors = ['ms', 'moz', 'webkit', 'o'];
				for(var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
					window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
					window.cancelAnimationFrame = window[vendors[x]+'CancelAnimationFrame'] 
											   || window[vendors[x]+'CancelRequestAnimationFrame'];
				}
				
				if (!window.requestAnimationFrame)
					window.requestAnimationFrame = function(callback, element) {
						var currTime = new Date().getTime();
						var timeToCall = Math.max(0, 16 - (currTime - lastTime));
						var id = window.setTimeout(function() { callback(currTime + timeToCall); }, 
						  timeToCall);
						lastTime = currTime + timeToCall;
						return id;
					};
				
				if (!window.cancelAnimationFrame)
					window.cancelAnimationFrame = function(id) {
						clearTimeout(id);
					};
				
				window.requestAnimFrame = window.requestAnimationFrame;
			");
			
			__triggerFrame ();
			
		#elseif flash
			
			Lib.current.stage.addEventListener (flash.events.Event.ENTER_FRAME, __triggerFrame);
			
		#elseif java
			
			if (window != null) {
				
				while (GLFW.glfwWindowShouldClose (window.handle) == GL11.GL_FALSE) {
					
					__triggerFrame ();
					
					GLFW.glfwSwapBuffers (window.handle);
					GLFW.glfwPollEvents ();
					
				}
				
			}
			
		#end
		
		return 0;
		
	}
	
	
	/**
	 * The init() method is called once before the first render()
	 * call. This can be used to do initial set-up for the current
	 * render context
	 * @param	context The current render context
	 */
	public function init (context:RenderContext):Void {
		
		
		
	}
	
	
	/**
	 * Called when a key down event is fired
	 * @param	keyCode	The code of the key that was pressed
	 * @param	modifier	The modifier of the key that was pressed
	 */
	public function onKeyDown (keyCode:Int, modifier:Int):Void { }
	
	
	/**
	 * Called when a key up event is fired
	 * @param	keyCode	The code of the key that was released
	 * @param	modifier	The modifier of the key that was released
	 */
	public function onKeyUp (keyCode:Int, modifier:Int):Void { }
	
	
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
	 * Called when a render event is fired
	 * @param	context	The current render context
	 */
	public function render (context:RenderContext):Void {
		
		
		
	}
	
	
	/**
	 * Called when an update event is fired
	 * @param	deltaTime	The amount of time in milliseconds that has elapsed since the last update
	 */
	public function update (deltaTime:Int):Void {
		
		
		
	}
	
	
	@:noCompletion private function __cleanup():Void {
		
		#if (cpp || neko || nodejs)
			
			AudioManager.shutdown();
			
		#end
		
	}
	
	
	@:noCompletion private static function __dispatch ():Void {
		
		#if (js && stats)
			
			__instance.window.stats.begin ();
			
		#end
		
		__instance.update (__eventInfo.deltaTime);
		onUpdate.dispatch (__eventInfo.deltaTime);
		
	}
	
	
	@:noCompletion private function __triggerFrame (?__):Void {
		
		__eventInfo.deltaTime = 16; //TODO
		__dispatch ();
		
		Renderer.render ();
		
		#if (js && html5)
			
			Browser.window.requestAnimationFrame (cast __triggerFrame);
			
		#end
		
	}
	
	
	@:noCompletion private inline function get_window ():Window {
		
		return windows[0];
		
	}
	
	
	#if (cpp || neko || nodejs)
	private static var lime_application_create = System.load ("lime", "lime_application_create", 1);
	private static var lime_application_init = System.load ("lime", "lime_application_init", 1);
	private static var lime_application_update = System.load ("lime", "lime_application_update", 1);
	private static var lime_application_quit = System.load ("lime", "lime_application_quit", 1);
	private static var lime_application_get_ticks = System.load ("lime", "lime_application_get_ticks", 0);
	private static var lime_update_event_manager_register = System.load ("lime", "lime_update_event_manager_register", 2);
	#end
	
	
}


private class UpdateEventInfo {
	
	
	public var deltaTime:Int;
	public var type:UpdateEventType;
	
	
	public function new (type:UpdateEventType = null, deltaTime:Int = 0) {
		
		this.type = type;
		this.deltaTime = deltaTime;
		
	}
	
	
	public function clone ():UpdateEventInfo {
		
		return new UpdateEventInfo (type, deltaTime);
		
	}
	
	
}


@:enum private abstract UpdateEventType(Int) {
	
	var UPDATE = 0;
	
}