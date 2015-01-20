package lime.ui;


import lime.app.Event;


class KeyEventManager {
	
	
	public static var onKeyDown = new Event<Int->Int->Void> ();
	public static var onKeyUp = new Event<Int->Int->Void> ();
	
	
	public static function create ():Void {
		
		KeyEventManagerBackend.create ();
		
	}
	
	
	private static function registerWindow (_window:Window):Void {
		
		
		
	}
	
	
}


#if flash
@:noCompletion private typedef KeyEventManagerBackend = lime._backend.flash.FlashKeyEventManager;
#elseif (js && html5)
@:noCompletion private typedef KeyEventManagerBackend = lime._backend.html5.HTML5KeyEventManager;
#else
@:noCompletion private typedef KeyEventManagerBackend = lime._backend.native.NativeKeyEventManager;
#end