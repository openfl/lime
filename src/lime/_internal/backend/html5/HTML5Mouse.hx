package lime._internal.backend.html5;


import lime.app.Application;
import lime.ui.MouseCursor;
import lime.ui.Window;

@:access(lime.app.Application)
@:access(lime.ui.Window)


class HTML5Mouse {
	
	
	private static var __cursor:MouseCursor;
	private static var __hidden:Bool;
	
	
	public static function hide ():Void {
		
		if (!__hidden) {
			
			__hidden = true;
			
			for (window in Application.current.windows) {
				
				window.__backend.hideCursor ();
				
			}
			
		}
		
	}
	
	
	public static function show ():Void {
		
		if (__hidden) {
			
			__hidden = false;
			
			for (window in Application.current.windows) {
				
				window.__backend.showCursor ();
				
			}
			
		}
		
	}
	
	
	public static function warp (x:Int, y:Int, window:Window):Void {
		
		
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	public static function get_cursor ():MouseCursor {
		
		if (__cursor == null) return DEFAULT;
		return __cursor;
		
	}
	
	
	public static function set_cursor (value:MouseCursor):MouseCursor {
		
		if (__cursor != value) {
			
			for (window in Application.current.windows) {
				
				window.__backend.setCursor (value);
				
			}
			
			__cursor = value;
			
		}
		
		return __cursor;
		
	}
	
	
	public static function get_lock ():Bool {
		
		return false;
		
	}
	
	
	public static function set_lock (value:Bool):Bool {
		
		return value;
		
	}
	
	
	public static function get_visible ():Bool {
		
		return !__hidden;
		
	}
	
	
}