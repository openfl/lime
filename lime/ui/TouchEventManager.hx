package lime.ui;


import lime.app.Event;
import lime.system.System;

#if flash
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;
import flash.Lib;
#end


@:allow(lime.ui.Window) class TouchEventManager {
	
	
	public static var onTouchEnd = new Event<Float->Float->Int->Void> ();
	public static var onTouchMove = new Event<Float->Float->Int->Void> ();
	public static var onTouchStart = new Event<Float->Float->Int->Void> ();
	
	private static var eventInfo:TouchEventInfo;
	
	
	public static function create ():Void {
		
		eventInfo = new TouchEventInfo ();
		
		#if (cpp || neko)
		lime_touch_event_manager_register (handleEvent, eventInfo);
		#end
		
	}
	
	
	private static function handleEvent (#if js event:js.html.TouchEvent #elseif flash event:flash.events.TouchEvent #end):Void {
		
		#if js
		
		event.preventDefault ();
		
		//var rect = __canvas.getBoundingClientRect ();
		
		//touchEvent.id = event.changedTouches[0].identifier;
		eventInfo.x = event.pageX;
		eventInfo.y = event.pageY;
		
		eventInfo.type = switch (event.type) {
			
			case "touchstart": TOUCH_START;
			case "touchmove": TOUCH_MOVE;
			case "touchend": TOUCH_END;
			default: null;
			
		}
		
		/*
		event.preventDefault ();
		
		var rect;
		
		if (__canvas != null) {
			
			rect = __canvas.getBoundingClientRect ();
			
		} else {
			
			rect = __div.getBoundingClientRect ();
			
		}
		
		var touch = event.changedTouches[0];
		var point = new Point ((touch.pageX - rect.left) * (stageWidth / rect.width), (touch.pageY - rect.top) * (stageHeight / rect.height));
		
		__mouseX = point.x;
		__mouseY = point.y;
		
		__stack = [];
		
		var type = null;
		var mouseType = null;
		
		switch (event.type) {
			
			case "touchstart":
				
				type = TouchEvent.TOUCH_BEGIN;
				mouseType = MouseEvent.MOUSE_DOWN;
			
			case "touchmove":
				
				type = TouchEvent.TOUCH_MOVE;
				mouseType = MouseEvent.MOUSE_MOVE;
			
			case "touchend":
				
				type = TouchEvent.TOUCH_END;
				mouseType = MouseEvent.MOUSE_UP;
			
			default:
			
		}
		*/
		
		#elseif flash
		
		//touchEvent.id = event.touchPointID;
		eventInfo.x = event.stageX;
		eventInfo.y = event.stageY;
		
		eventInfo.type = switch (event.type) {
			
			case flash.events.TouchEvent.TOUCH_BEGIN: TOUCH_START;
			case flash.events.TouchEvent.TOUCH_MOVE: TOUCH_MOVE;
			default: TOUCH_END;
			
		}
		
		#end
		
		switch (eventInfo.type) {
			
			case TOUCH_START:
				
				onTouchStart.dispatch (eventInfo.x, eventInfo.y, eventInfo.id);
			
			case TOUCH_END:
				
				onTouchEnd.dispatch (eventInfo.x, eventInfo.y, eventInfo.id);
			
			case TOUCH_MOVE:
				
				onTouchMove.dispatch (eventInfo.x, eventInfo.y, eventInfo.id);
			
		}
		
	}
	
	
	private static function registerWindow (window:Window):Void {
		
		#if js
		
		window.element.addEventListener ("touchstart", handleEvent, true);
		window.element.addEventListener ("touchmove", handleEvent, true);
		window.element.addEventListener ("touchend", handleEvent, true);
		
		#elseif flash
		
		Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
		Lib.current.stage.addEventListener (flash.events.TouchEvent.TOUCH_BEGIN, handleEvent);
		Lib.current.stage.addEventListener (flash.events.TouchEvent.TOUCH_MOVE, handleEvent);
		Lib.current.stage.addEventListener (flash.events.TouchEvent.TOUCH_END, handleEvent);
		
		#end
		
	}
	
	
	#if (cpp || neko)
	private static var lime_touch_event_manager_register = System.load ("lime", "lime_touch_event_manager_register", 2);
	#end
	
	
}


private class TouchEventInfo {
	
	
	public var id:Int;
	public var type:TouchEventType;
	public var x:Float;
	public var y:Float;
	
	
	public function new (type:TouchEventType = null, x:Float = 0, y:Float = 0, id:Int = 0) {
		
		this.type = type;
		this.x = x;
		this.y = y;
		this.id = id;
		
	}
	
	
	public function clone ():TouchEventInfo {
		
		return new TouchEventInfo (type, x, y, id);
		
	}
	
	
}


@:enum private abstract TouchEventType(Int) {
	
	var TOUCH_START = 0;
	var TOUCH_END = 1;
	var TOUCH_MOVE = 2;
	
}