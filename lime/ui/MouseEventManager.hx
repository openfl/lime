package lime.ui;


import lime.app.Event;
import lime.system.System;

#if (js && html5)
import js.Browser;
#elseif flash
import flash.Lib;
#end


@:allow(lime.ui.Window)
class MouseEventManager {
	
	
	public static var onMouseDown = new Event<Float->Float->Int->Void> ();
	public static var onMouseMove = new Event<Float->Float->Int->Void> ();
	public static var onMouseUp = new Event<Float->Float->Int->Void> ();
	public static var onMouseWheel = new Event<Float->Float->Void> ();
	
	private static var created:Bool;
	private static var eventInfo:MouseEventInfo;
	
	#if (js && html5)
	private static var window:Window;
	#end
	
	
	public static function create ():Void {
		
		eventInfo = new MouseEventInfo ();
		
		#if (cpp || neko || nodejs)
		lime_mouse_event_manager_register (handleEvent, eventInfo);
		#end
		
	}
	
	
	private static function handleEvent (#if (js && html5) event:js.html.MouseEvent #elseif flash event:flash.events.MouseEvent #end):Void {
		
		#if (js && html5)
		
		eventInfo.type = switch (event.type) {
			
			case "mousedown": MOUSE_DOWN;
			case "mouseup": MOUSE_UP;
			case "mousemove": MOUSE_MOVE;
			//case "click": MouseEvent.CLICK;
			//case "dblclick": MouseEvent.DOUBLE_CLICK;
			case "wheel": MOUSE_WHEEL;
			default: null;
			
		}
		
		if (eventInfo.type != MOUSE_WHEEL) {
			
			if (window != null && window.element != null) {
				
				if (window.canvas != null) {
					
					var rect = window.canvas.getBoundingClientRect ();
					eventInfo.x = (event.clientX - rect.left) * (window.width / rect.width);
					eventInfo.y = (event.clientY - rect.top) * (window.height / rect.height);
					
				} else if (window.div != null) {
					
					var rect = window.div.getBoundingClientRect ();
					//eventInfo.x = (event.clientX - rect.left) * (window.div.style.width / rect.width);
					eventInfo.x = (event.clientX - rect.left);
					//eventInfo.y = (event.clientY - rect.top) * (window.div.style.height / rect.height);
					eventInfo.y = (event.clientY - rect.top);
					
				} else {
					
					var rect = window.element.getBoundingClientRect ();
					eventInfo.x = (event.clientX - rect.left) * (window.width / rect.width);
					eventInfo.y = (event.clientY - rect.top) * (window.height / rect.height);
					
				}
				
			} else {
				
				eventInfo.x = event.clientX;
				eventInfo.y = event.clientY;
				
			}
			
		} else {
			
			eventInfo.x = untyped event.deltaX;
			eventInfo.y = untyped event.deltaY;
			
		}
		
		eventInfo.button = event.button;
		
		#elseif flash
		
		eventInfo.type = switch (event.type) {
			
			case "mouseDown", "middleMouseDown", "rightMouseDown": MOUSE_DOWN;
			case "mouseMove", "middleMouseMove", "rightMouseMove": MOUSE_MOVE;
			case "mouseUp", "middleMouseUp", "rightMouseUp": MOUSE_UP;
			default: MOUSE_WHEEL;
			
		}
		
		if (eventInfo.type != MOUSE_WHEEL) {
			
			eventInfo.x = event.stageX;
			eventInfo.y = event.stageY;
			
		} else {
			
			eventInfo.x = 0;
			eventInfo.y = event.delta;
			
		}
		
		eventInfo.button = switch (event.type) {
			
			case "middleMouseDown", "middleMouseMove", "middleMouseUp": 1;
			case "rightMouseDown", "rightMouseMove", "rightMouseUp": 2;
			default: 0;
			
		}
		
		#end
		
		switch (eventInfo.type) {
			
			case MOUSE_DOWN:
				
				onMouseDown.dispatch (eventInfo.x, eventInfo.y, eventInfo.button);
			
			case MOUSE_UP:
				
				onMouseUp.dispatch (eventInfo.x, eventInfo.y, eventInfo.button);
			
			case MOUSE_MOVE:
				
				onMouseMove.dispatch (eventInfo.x, eventInfo.y, eventInfo.button);
			
			case MOUSE_WHEEL:
				
				onMouseWheel.dispatch (eventInfo.x, eventInfo.y);
			
			default:
			
		}
		
	}
	
	
	private static function registerWindow (_window:Window):Void {
		
		#if (js && html5)
		
		var events = [ "mousedown", "mousemove", "mouseup", "wheel" ];
		
		for (event in events) {
			
			_window.element.addEventListener (event, handleEvent, true);
			
		}
		
		MouseEventManager.window = _window;
		
		// Disable image drag on Firefox
		Browser.document.addEventListener ("dragstart", function (e) {
			if (e.target.nodeName.toLowerCase () == "img") {
				e.preventDefault ();
				return false;
			}
			return true;
		}, false);
		
		#elseif flash
		
		var events = [ "mouseDown", "mouseMove", "mouseUp", "mouseWheel", "middleMouseDown", "middleMouseMove", "middleMouseUp", "rightMouseDown", "rightMouseMove", "rightMouseUp" ];
		
		for (event in events) {
			
			Lib.current.stage.addEventListener (event, handleEvent);
			
		}
		
		#end
		
	}
	
	
	#if (cpp || neko || nodejs)
	private static var lime_mouse_event_manager_register = System.load ("lime", "lime_mouse_event_manager_register", 2);
	#end
	
	
}


private class MouseEventInfo {
	
	
	public var button:Int;
	public var type:MouseEventType;
	public var x:Float;
	public var y:Float;
	
	
	
	public function new (type:MouseEventType = null, x:Float = 0, y:Float = 0, button:Int = 0) {
		
		this.type = type;
		this.x = x;
		this.y = y;
		this.button = button;
		
	}
	
	
	public function clone ():MouseEventInfo {
		
		return new MouseEventInfo (type, x, y, button);
		
	}
	
	
}


@:enum private abstract MouseEventType(Int) {
	
	var MOUSE_DOWN = 0;
	var MOUSE_UP = 1;
	var MOUSE_MOVE = 2;
	var MOUSE_WHEEL = 3;
	
}