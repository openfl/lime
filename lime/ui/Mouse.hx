package lime.ui;


import lime.app.Application;

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
				
				#end
				
			}
			
			__cursor = value;
			
		}
		
		return __cursor;
		
	}
	
	
}