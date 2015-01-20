package lime.ui;


import lime.app.Event;
import lime.ui.Window;


class MouseEventManager {
	
	
	public static var onMouseDown = new Event<Float->Float->Int->Void> ();
	public static var onMouseMove = new Event<Float->Float->Int->Void> ();
	public static var onMouseUp = new Event<Float->Float->Int->Void> ();
	public static var onMouseWheel = new Event<Float->Float->Void> ();
	
	
	public static function create ():Void {
		
		MouseEventManagerBackend.create ();
		
	}
	
	
	private static function registerWindow (window:Window):Void {
		
		MouseEventManagerBackend.registerWindow (window);
		
	}
	
	
}


#if flash
@:noCompletion private typedef MouseEventManagerBackend = lime._backend.flash.FlashMouseEventManager;
#elseif (js && html5)
@:noCompletion private typedef MouseEventManagerBackend = lime._backend.html5.HTML5MouseEventManager;
#else
@:noCompletion private typedef MouseEventManagerBackend = lime._backend.native.NativeMouseEventManager;
#end