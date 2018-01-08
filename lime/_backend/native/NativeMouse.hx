package lime._backend.native;


import lime._backend.native.NativeCFFI;
import lime.ui.MouseCursor;
import lime.ui.Window;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)
@:access(lime.ui.Window)


class NativeMouse {
	
	
	private static var __cursor:MouseCursor;
	private static var __hidden:Bool;
	private static var __lock:Bool;
	
	
	public static function hide ():Void {
		
		if (!__hidden) {
			
			__hidden = true;
			
			#if (!macro && lime_cffi)
			NativeCFFI.lime_mouse_hide ();
			#end
			
		}
		
	}
	
	
	public static function show ():Void {
		
		if (__hidden) {
			
			__hidden = false;
			
			#if (!macro && lime_cffi)
			NativeCFFI.lime_mouse_show ();
			#end
			
		}
		
	}
	
	
	public static function warp (x:Int, y:Int, window:Window):Void {
		
		#if (!macro && lime_cffi)
		NativeCFFI.lime_mouse_warp (x, y, window == null ? 0 : window.backend.handle);
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	public static function get_cursor ():MouseCursor {
		
		if (__cursor == null) return DEFAULT;
		return __cursor;
		
	}
	
	
	public static function set_cursor (value:MouseCursor):MouseCursor {
		
		if (__cursor != value) {
			
			if (!__hidden) {
				
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
				
				#if (!macro && lime_cffi)
				NativeCFFI.lime_mouse_set_cursor (type);
				#end
				
			}
			
			__cursor = value;
			
		}
		
		return __cursor;
		
	}
	
	
	public static function get_lock ():Bool {
		
		return __lock;
		
	}
	
	
	public static function set_lock (value:Bool):Bool {
		
		if (__lock != value) {
			
			#if (!macro && lime_cffi)
			NativeCFFI.lime_mouse_set_lock (value);
			#end
			
			__hidden = value;
			__lock = value;
			
		}
		
		return __lock;
		
	}
	
	
}


@:enum private abstract MouseCursorType(Int) from Int to Int {
	
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