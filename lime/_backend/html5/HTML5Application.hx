package lime._backend.html5;


import js.html.KeyboardEvent;
import js.Browser;
import lime.app.Application;
import lime.app.Config;
import lime.audio.AudioManager;
import lime.graphics.Renderer;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Window;

@:access(lime._backend.html5.HTML5Window)
@:access(lime.app.Application)
@:access(lime.graphics.Renderer)
@:access(lime.ui.Window)


class HTML5Application {
	
	
	private var currentUpdate:Float;
	private var deltaTime:Float;
	private var framePeriod:Float;
	private var lastUpdate:Float;
	private var nextUpdate:Float;
	private var parent:Application;
	#if stats
	private var stats:Dynamic;
	#end
	
	
	public inline function new (parent:Application) {
		
		this.parent = parent;
		
		currentUpdate = 0;
		lastUpdate = 0;
		nextUpdate = 0;
		framePeriod = -1;
		
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
			case 124: return KeyCode.F13;
			case 125: return KeyCode.F14;
			case 126: return KeyCode.F15;
			case 186: return KeyCode.SEMICOLON;
			case 187: return KeyCode.EQUALS;
			case 188: return KeyCode.COMMA;
			case 189: return KeyCode.MINUS;
			case 190: return KeyCode.PERIOD;
			case 191: return KeyCode.SLASH;
			case 192: return KeyCode.GRAVE;
			case 219: return KeyCode.LEFT_BRACKET;
			case 220: return KeyCode.BACKSLASH;
			case 221: return KeyCode.RIGHT_BRACKET;
			case 222: return KeyCode.SINGLE_QUOTE;
			
		}
		
		return keyCode;
		
	}
	
	
	public function create (config:Config):Void {
		
		
		
	}
	
	
	public function exec ():Int {
		
		Browser.window.addEventListener ("keydown", handleKeyEvent, false);
		Browser.window.addEventListener ("keyup", handleKeyEvent, false);
		Browser.window.addEventListener ("focus", handleWindowEvent, false);
		Browser.window.addEventListener ("blur", handleWindowEvent, false);
		Browser.window.addEventListener ("resize", handleWindowEvent, false);
		Browser.window.addEventListener ("beforeunload", handleWindowEvent, false);
		
		#if stats
		stats = untyped __js__("new Stats ()");
		stats.domElement.style.position = "absolute";
		stats.domElement.style.top = "0px";
		Browser.document.body.appendChild (stats.domElement);
		#end
		
		untyped __js__ ("
			var lastTime = 0;
			var vendors = ['ms', 'moz', 'webkit', 'o'];
			for (var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
				window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
				window.cancelAnimationFrame = window[vendors[x]+'CancelAnimationFrame'] || window[vendors[x]+'CancelRequestAnimationFrame'];
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
		
		lastUpdate = Date.now ().getTime ();
		
		handleApplicationEvent ();
		
		return 0;
		
	}
	
	
	public function exit ():Void {
		
		
		
	}
	
	
	public function getFrameRate ():Float {
		
		if (framePeriod < 0) {
			
			return 60;
			
		} else if (framePeriod == 1000) {
			
			return 0;
			
		} else {
			
			return 1000 / framePeriod;
			
		}
		
	}
	
	
	private function handleApplicationEvent (?__):Void {
		
		currentUpdate = Date.now ().getTime ();
		
		if (currentUpdate >= nextUpdate) {
			
			#if stats
			stats.begin ();
			#end
			
			deltaTime = currentUpdate - lastUpdate;
			
			parent.onUpdate.dispatch (Std.int (deltaTime));
			
			if (parent.renderer != null) {
				
				parent.renderer.onRender.dispatch ();
				parent.renderer.flip ();
				
			}
			
			#if stats
			stats.end ();
			#end
			
			if (framePeriod < 0) {
				
				nextUpdate = currentUpdate;
				nextUpdate = currentUpdate;
				
			} else {
				
				nextUpdate = currentUpdate + framePeriod;
				
				//while (nextUpdate <= currentUpdate) {
					//
					//nextUpdate += framePeriod;
					//
				//}
				
				
			}
			
			lastUpdate = currentUpdate;
			
		}
		
		Browser.window.requestAnimationFrame (cast handleApplicationEvent);
		
	}
	
	
	private function handleKeyEvent (event:KeyboardEvent):Void {
		
		if (parent.window != null) {
			
			// space and arrow keys
			
			// switch (event.keyCode) {
				
			// 	case 32, 37, 38, 39, 40: event.preventDefault ();
				
			// }
			
			var keyCode = cast convertKeyCode (event.keyCode != null ? event.keyCode : event.which);
			var modifier = (event.shiftKey ? (KeyModifier.SHIFT) : 0) | (event.ctrlKey ? (KeyModifier.CTRL) : 0) | (event.altKey ? (KeyModifier.ALT) : 0) | (event.metaKey ? (KeyModifier.META) : 0);
			
			if (event.type == "keydown") {
				
				parent.window.onKeyDown.dispatch (keyCode, modifier);
				
			} else {
				
				parent.window.onKeyUp.dispatch (keyCode, modifier);
				
			}
			
		}
		
	}
	
	
	private function handleWindowEvent (event:js.html.Event):Void {
		
		if (parent.window != null) {
			
			switch (event.type) {
				
				case "focus":
					
					parent.window.onFocusIn.dispatch ();
					parent.window.onActivate.dispatch ();
				
				case "blur":
					
					parent.window.onFocusOut.dispatch ();
					parent.window.onDeactivate.dispatch ();
				
				case "resize":
					
					var cacheWidth = parent.window.width;
					var cacheHeight = parent.window.height;
					
					parent.window.backend.handleResize ();
					
					if (parent.window.width != cacheWidth || parent.window.height != cacheHeight) {
						
						parent.window.onResize.dispatch (parent.window.width, parent.window.height);
						
					}
				
				case "beforeunload":
					
					parent.window.onClose.dispatch ();
				
			}
			
		}
		
	}
	
	
	public function setFrameRate (value:Float):Float {
		
		if (value >= 60) {
			
			framePeriod = -1;
			
		} else if (value > 0) {
			
			framePeriod = 1000 / value;
			
		} else {
			
			framePeriod = 1000;
			
		}
		
		return value;
		
	}
	
	
}
