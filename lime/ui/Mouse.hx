package lime.ui;


import lime.app.Application;
import lime.system.System;

@:access(lime.app.Application)


class Mouse {
	
	
	public static var cursor (get, set):MouseCursor;
	
	
	private static var __cursor:MouseCursor;
	private static var __hidden:Bool;
	
	
	public static function hide ():Void {
		
		if (!__hidden) {
			
			#if (js && html5)
			
			for (window in Application.__instance.windows) {
				
				window.element.style.cursor = "none";
				
			}
			
			#elseif (cpp || neko || nodejs)
			
			lime_mouse_hide ();
			
			#end
			
			__hidden = true;
			
		}
		
	}
	
	
	public static function show ():Void {
		
		if (__hidden) {
			
			#if (js && html5)
			
			var cacheValue = __cursor;
			__cursor = null;
			cursor = cacheValue;
			
			#elseif (cpp || neko || nodejs)
			
			lime_mouse_show ();
			
			#end
			
			__hidden = false;
			
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
						
						case POINTER: "pointer";
						case TEXT: "text";
						default: "default";
						
					}
					
				}
				
				#elseif (cpp || neko || nodejs)
				
				var type = switch (value) {
					
					case POINTER: MouseCursorType.POINTER;
					case TEXT: MouseCursorType.TEXT;
					default: MouseCursorType.DEFAULT;
					
				}
				
				lime_mouse_set_cursor (type);
				
				#end
				
			}
			
			__cursor = value;
			
		}
		
		return __cursor;
		
	}
	
	
	#if (cpp || neko || nodejs)
	private static var lime_mouse_hide = System.load ("lime", "lime_mouse_hide", 0);
	private static var lime_mouse_set_cursor = System.load ("lime", "lime_mouse_set_cursor", 1);
	private static var lime_mouse_show = System.load ("lime", "lime_mouse_show", 0);
	#end
	
	
}


@:enum private abstract MouseCursorType(Int) {
	
	var DEFAULT = 0;
	var POINTER = 1;
	var TEXT = 2;
	
}