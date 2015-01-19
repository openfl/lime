package lime._backend.html5;


import js.Browser;
import lime.app.Application;
import lime.app.Config;
import lime.audio.AudioManager;
import lime.graphics.Renderer;
import lime.ui.KeyEventManager;
import lime.ui.MouseEventManager;
import lime.ui.TouchEventManager;
import lime.ui.Window;

@:access(lime.app.Application)
@:access(lime.graphics.Renderer)


class HTML5Application {
	
	
	private static var __registered:Bool;
	
	private var parent:Application;
	
	
	public inline function new (parent:Application) {
		
		this.parent = parent;
		
		Application.__instance = parent;
		
		if (!__registered) {
			
			__registered = true;
			
			AudioManager.init ();
			
		}
		
	}
	
	
	public function create (config:Config):Void {
		
		parent.config = config;
		
		KeyEventManager.create ();
		MouseEventManager.create ();
		TouchEventManager.create ();
		
		KeyEventManager.onKeyDown.add (parent.onKeyDown);
		KeyEventManager.onKeyUp.add (parent.onKeyUp);
		
		MouseEventManager.onMouseDown.add (parent.onMouseDown);
		MouseEventManager.onMouseMove.add (parent.onMouseMove);
		MouseEventManager.onMouseUp.add (parent.onMouseUp);
		MouseEventManager.onMouseWheel.add (parent.onMouseWheel);
		
		TouchEventManager.onTouchStart.add (parent.onTouchStart);
		TouchEventManager.onTouchMove.add (parent.onTouchMove);
		TouchEventManager.onTouchEnd.add (parent.onTouchEnd);
		
		Renderer.onRenderContextLost.add (parent.onRenderContextLost);
		Renderer.onRenderContextRestored.add (parent.onRenderContextRestored);
		
		Window.onWindowActivate.add (parent.onWindowActivate);
		Window.onWindowClose.add (parent.onWindowClose);
		Window.onWindowDeactivate.add (parent.onWindowDeactivate);
		Window.onWindowFocusIn.add (parent.onWindowFocusIn);
		Window.onWindowFocusOut.add (parent.onWindowFocusOut);
		Window.onWindowMove.add (parent.onWindowMove);
		Window.onWindowResize.add (parent.onWindowResize);
		
		var window = new Window (config);
		var renderer = new Renderer (window);
		
		window.width = config.width;
		window.height = config.height;
		window.backend.element = config.element;
		
		parent.addWindow (window);
		
	}
	
	
	public function exec ():Int {
		
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
		
		return 0;
		
	}
	
	
	private static function __dispatch ():Void {
		
		#if stats
		Application.__instance.window.stats.begin ();
		#end
		
		Application.__instance.update (16);
		Application.onUpdate.dispatch (16);
		
	}
	
	
	private static function __triggerFrame (?__):Void {
		
		__dispatch ();
		
		Renderer.render ();
		
		Browser.window.requestAnimationFrame (cast __triggerFrame);
		
	}
	
	
}