package lime.ui;


class Mouse {
	
	
	public static var cursor (get, set):MouseCursor;
	public static var lock (get, set):Bool;
  public static var captureMode(get, set):Bool;
  
  private static function set_captureMode(v:Bool):Bool
  {
    return MouseBackend.set_captureMode(v);
  }
  
  private static function get_captureMode():Bool
  {
    return MouseBackend.get_captureMode();
  }
	
	
	public static function hide ():Void {
		
		MouseBackend.hide ();
		
	}
	
	
	public static function show ():Void {
		
		MouseBackend.show ();
		
	}
	
	
	public static function warp (x:Int, y:Int, window:Window = null):Void {
		
		MouseBackend.warp (x, y, window);
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private static function get_cursor ():MouseCursor {
		
		return MouseBackend.get_cursor ();
		
	}
	
	
	private static function set_cursor (value:MouseCursor):MouseCursor {
		
		return MouseBackend.set_cursor (value);
		
	}
	
	
	private static function get_lock ():Bool {
		
		return MouseBackend.get_lock ();
		
	}
	
	
	private static function set_lock (value:Bool):Bool {
		
		return MouseBackend.set_lock (value);
		
	}
	
	
}


#if flash
@:noCompletion private typedef MouseBackend = lime._backend.flash.FlashMouse;
#elseif (js && html5)
@:noCompletion private typedef MouseBackend = lime._backend.html5.HTML5Mouse;
#else
@:noCompletion private typedef MouseBackend = lime._backend.native.NativeMouse;
#end