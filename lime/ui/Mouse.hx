package lime.ui;


import lime.app.Application;
import lime.system.System;

#if flash
import flash.ui.Mouse in FlashMouse;
import flash.ui.MouseCursor in FlashMouseCursor;
#end

@:access(lime.app.Application)


class Mouse {
	
	
	public static var cursor (get, set):MouseCursor;
	
	
	private static var __cursor:MouseCursor;
	private static var __hidden:Bool;
	
	
	public static function hide ():Void {
		
		if (!__hidden) {
			
			__hidden = true;
			
			#if (js && html5)
				
				for (window in Application.__instance.windows) {
					
					window.element.style.cursor = "none";
					
				}
				
			#elseif (cpp || neko || nodejs)
				
				lime_mouse_hide ();
				
			#elseif flash
				
				FlashMouse.hide ();
				
			#end
			
		}
		
	}
	
	
	public static function show ():Void {
		
		if (__hidden) {
			
			__hidden = false;
			
			#if (js && html5)
				
				var cacheValue = __cursor;
				__cursor = null;
				cursor = cacheValue;
				
			#elseif (cpp || neko || nodejs)
				
				lime_mouse_show ();
				
			#elseif flash
				
				FlashMouse.show ();
				
			#end
			
		}
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private static function get_cursor ():MouseCursor {
		
		if (__cursor == null) return DEFAULT;
		return __cursor;
		
	}
	
	
	private static function set_cursor (value:MouseCursor):MouseCursor {
		
		if (__cursor != value) {
			
			if (!__hidden) {
				
				#if (js && html5)
					
					for (window in Application.__instance.windows) {
						
						window.element.style.cursor = switch (value) {
							
							case ARROW: "default";
							case CROSSHAIR: "crosshair";
							case MOVE: "move";
							case POINTER: "pointer";
							case RESIZE_NESW: "nesw-resize";
							case RESIZE_NS: "ns-resize";
							case RESIZE_NWSE: "nwse-resize";
							case RESIZE_WE: "ew-resize";
							case TEXT: "text";
							case WAIT: "wait";
							case WAIT_ARROW: "wait";
							default: "auto";
							
						}
						
					}
					
				#elseif (cpp || neko || nodejs)
					
					var type:MouseCursorType = switch (value) {
						
						case ARROW: ARROW;
						case CROSSHAIR: CROSSHAIR;
						case MOVE: MOVE;
						case POINTER: POINTER;
						case RESIZE_NESW: RESIZE_NESW;
						case RESIZE_NS: RESIZE_NS;
						case RESIZE_NWSE: RESIZE_NWSE;
						case RESIZE_WE: RESIZE_WE;
						case TEXT: TEXT;
						case WAIT: WAIT;
						case WAIT_ARROW: WAIT_ARROW;
						default: DEFAULT;
						
					}
					
					lime_mouse_set_cursor (type);
					
				#elseif flash
					
					FlashMouse.cursor = switch (value) {
						
						case ARROW: FlashMouseCursor.ARROW;
						case CROSSHAIR: FlashMouseCursor.ARROW;
						case MOVE: FlashMouseCursor.HAND;
						case POINTER: FlashMouseCursor.BUTTON;
						case RESIZE_NESW: FlashMouseCursor.HAND;
						case RESIZE_NS: FlashMouseCursor.HAND;
						case RESIZE_NWSE: FlashMouseCursor.HAND;
						case RESIZE_WE: FlashMouseCursor.HAND;
						case TEXT: FlashMouseCursor.IBEAM;
						case WAIT: FlashMouseCursor.ARROW;
						case WAIT_ARROW: FlashMouseCursor.ARROW;
						default: FlashMouseCursor.AUTO;
						
					}
					
				#end
				
			}
			
			__cursor = value;
			
		}
		
		return __cursor;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_mouse_hide = System.load ("lime", "lime_mouse_hide", 0);
	private static var lime_mouse_set_cursor = System.load ("lime", "lime_mouse_set_cursor", 1);
	private static var lime_mouse_show = System.load ("lime", "lime_mouse_show", 0);
	#end
	
	
}


@:enum private abstract MouseCursorType(Int) {
	
	var ARROW = 0;
	var CROSSHAIR = 1;
	var DEFAULT = 2;
	var MOVE = 3;
	var POINTER = 4;
	var RESIZE_NESW = 5;
	var RESIZE_NS = 6;
	var RESIZE_NWSE = 7;
	var RESIZE_WE = 8;
	var TEXT = 9;
	var WAIT = 10;
	var WAIT_ARROW = 11;
	
}