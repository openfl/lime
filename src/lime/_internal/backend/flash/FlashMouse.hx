package lime._internal.backend.flash;


import flash.ui.Mouse;
import flash.ui.MouseCursor in FlashMouseCursor;
import lime.ui.MouseCursor;
import lime.ui.Window;


class FlashMouse {
	
	
	private static var __cursor:MouseCursor;
	private static var __hidden:Bool;
	
	
	public static function hide ():Void {
		
		if (!__hidden) {
			
			__hidden = true;
			
			Mouse.hide ();
			
		}
		
	}
	
	
	public static function show ():Void {
		
		if (__hidden) {
			
			__hidden = false;
			
			Mouse.show ();
			
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
			
			if (!__hidden) {
				
				Mouse.cursor = switch (value) {
					
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
	
	
}