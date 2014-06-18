package lime.ui;


import lime.app.EventManager;
import lime.system.System;

#if flash
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;
import flash.Lib;
#end


@:allow(lime.ui.Window)
class TouchEventManager extends EventManager<ITouchEventListener> {
	
	
	private static var instance:TouchEventManager;
	
	private var eventInfo:TouchEventInfo;
	
	
	public function new () {
		
		super ();
		
		instance = this;
		eventInfo = new TouchEventInfo ();
		
		#if (cpp || neko)
		lime_touch_event_manager_register (dispatch, eventInfo);
		#end
		
	}
	
	
	public static function addEventListener (listener:ITouchEventListener, priority:Int = 0):Void {
		
		if (instance != null) {
			
			instance._addEventListener (listener, priority);
			
		}
		
	}
	
	
	private function dispatch ():Void {
		
		var x = eventInfo.x;
		var y = eventInfo.y;
		var id = eventInfo.id;
		
		switch (eventInfo.type) {
			
			case TOUCH_START:
				
				for (listener in listeners) {
					
					listener.onTouchStart (x, y, id);
					
				}
			
			case TOUCH_END:
				
				for (listener in listeners) {
					
					listener.onTouchEnd (x, y, id);
					
				}
			
			case TOUCH_MOVE:
				
				for (listener in listeners) {
					
					listener.onTouchMove (x, y, id);
					
				}
			
		}
		
	}
	
	
	#if js
	private function handleDOMEvent (event:js.html.TouchEvent):Void {
		
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
		
		dispatch ();
		
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
		
	}
	#end
	
	
	#if flash
	private function handleFlashEvent (event:flash.events.TouchEvent):Void {
		
		//touchEvent.id = event.touchPointID;
		eventInfo.x = event.stageX;
		eventInfo.y = event.stageY;
		
		eventInfo.type = switch (event.type) {
			
			case flash.events.TouchEvent.TOUCH_BEGIN: TOUCH_START;
			case flash.events.TouchEvent.TOUCH_MOVE: TOUCH_MOVE;
			default: TOUCH_END;
			
		}
		
		dispatch ();
		
	}
	#end
	
	
	private static function registerWindow (window:Window):Void {
		
		if (instance != null) {
			
			#if js
			window.element.addEventListener ("touchstart", instance.handleDOMEvent, true);
			window.element.addEventListener ("touchmove", instance.handleDOMEvent, true);
			window.element.addEventListener ("touchend", instance.handleDOMEvent, true);
			#elseif flash
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			Lib.current.stage.addEventListener (flash.events.TouchEvent.TOUCH_BEGIN, instance.handleFlashEvent);
			Lib.current.stage.addEventListener (flash.events.TouchEvent.TOUCH_MOVE, instance.handleFlashEvent);
			Lib.current.stage.addEventListener (flash.events.TouchEvent.TOUCH_END, instance.handleFlashEvent);
			#end
			
		}
		
	}
	
	
	public static function removeEventListener (listener:ITouchEventListener):Void {
		
		if (instance != null) {
			
			instance._removeEventListener (listener);
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_touch_event_manager_register = System.load ("lime", "lime_touch_event_manager_register", 2);
	#end
	
	
}