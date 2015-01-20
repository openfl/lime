package lime.ui;


class Mouse {
	
	
	public static var cursor (get, set):MouseCursor;
	
	
	public static function hide ():Void {
		
		MouseBackend.hide ();
		
	}
	
	
	public static function show ():Void {
		
		MouseBackend.show ();
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private static function get_cursor ():MouseCursor {
		
		return MouseBackend.get_cursor ();
		
	}
	
	
	private static function set_cursor (value:MouseCursor):MouseCursor {
		
		return MouseBackend.set_cursor (value);
		
	}
	
	
}


#if flash
@:noCompletion private typedef MouseBackend = lime._backend.flash.FlashMouse;
#elseif (js && html5)
@:noCompletion private typedef MouseBackend = lime._backend.html5.HTML5Mouse;
#else
@:noCompletion private typedef MouseBackend = lime._backend.native.NativeMouse;
#end