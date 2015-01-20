package lime._backend.html5;


import js.html.KeyboardEvent;
import js.Browser;
import lime.app.Application;
import lime.app.Config;
import lime.audio.AudioManager;
import lime.graphics.Renderer;
import lime.ui.KeyCode;
import lime.ui.KeyEventManager;
import lime.ui.MouseEventManager;
import lime.ui.TouchEventManager;
import lime.ui.Window;

@:access(lime.app.Application)
@:access(lime.graphics.Renderer)


class HTML5Application {
	
	
	private var parent:Application;
	
	
	public inline function new (parent:Application) {
		
		this.parent = parent;
		
		Application.__instance = parent;
		AudioManager.init ();
		
	}
	
	
	private function convertKeyCode (keyCode:Int):KeyCode {
		
		if (keyCode >= 65 && keyCode <= 90) {
			
			return keyCode + 32;
			
		}
		
		switch (keyCode) {
			
			case 16: return KeyCode.LEFT_SHIFT;
			case 17: return KeyCode.LEFT_CTRL;
			case 18: return KeyCode.LEFT_ALT;
			case 20: return KeyCode.CAPS_LOCK;
			case 144: return KeyCode.NUM_LOCK;
			case 37: return KeyCode.LEFT;
			case 38: return KeyCode.UP;
			case 39: return KeyCode.RIGHT;
			case 40: return KeyCode.DOWN;
			case 45: return KeyCode.INSERT;
			case 46: return KeyCode.DELETE;
			case 36: return KeyCode.HOME;
			case 35: return KeyCode.END;
			case 33: return KeyCode.PAGE_UP;
			case 34: return KeyCode.PAGE_DOWN;
			case 112: return KeyCode.F1;
			case 113: return KeyCode.F2;
			case 114: return KeyCode.F3;
			case 115: return KeyCode.F4;
			case 116: return KeyCode.F5;
			case 117: return KeyCode.F6;
			case 118: return KeyCode.F7;
			case 119: return KeyCode.F8;
			case 120: return KeyCode.F9;
			case 121: return KeyCode.F10;
			case 122: return KeyCode.F11;
			case 123: return KeyCode.F12;
			
		}
		
		return keyCode;
		
	}
	
	
	public function create (config:Config):Void {
		
		parent.config = config;
		
		Browser.window.addEventListener ("keydown", handleKeyEvent, false);
		Browser.window.addEventListener ("keyup", handleKeyEvent, false);
		
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
		
		handleUpdateEvent ();
		
		return 0;
		
	}
	
	
	private function handleKeyEvent (event:KeyboardEvent):Void {
		
		// space and arrow keys
		
		switch (event.keyCode) {
			
			case 32, 37, 38, 39, 40: event.preventDefault ();
			
		}
		
		var keyCode = cast convertKeyCode (event.keyCode != null ? event.keyCode : event.which);
		var modifier = 0;
		
		if (event.type == "keydown") {
			
			KeyEventManager.onKeyDown.dispatch (keyCode, modifier);
			
		} else {
			
			KeyEventManager.onKeyUp.dispatch (keyCode, modifier);
			
		}
		
	}
	
	
	private static function handleUpdateEvent (?__):Void {
		
		#if stats
		Application.__instance.window.stats.begin ();
		#end
		
		Application.__instance.update (16);
		Application.onUpdate.dispatch (16);
		
		Renderer.render ();
		
		Browser.window.requestAnimationFrame (cast handleUpdateEvent);
		
	}
	
	
}