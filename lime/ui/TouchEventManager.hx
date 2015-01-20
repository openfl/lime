package lime.ui;


import lime.app.Event;


class TouchEventManager {
	
	
	public static var onTouchEnd = new Event<Float->Float->Int->Void> ();
	public static var onTouchMove = new Event<Float->Float->Int->Void> ();
	public static var onTouchStart = new Event<Float->Float->Int->Void> ();
	
	
	public static function create ():Void {
		
		TouchEventManagerBackend.create ();
		
	}
	
	
	private static function registerWindow (window:Window):Void {
		
		TouchEventManagerBackend.registerWindow (window);
		
	}
	
	
}


#if flash
@:noCompletion private typedef TouchEventManagerBackend = lime._backend.flash.FlashTouchEventManager;
#elseif (js && html5)
@:noCompletion private typedef TouchEventManagerBackend = lime._backend.html5.HTML5TouchEventManager;
#else
@:noCompletion private typedef TouchEventManagerBackend = lime._backend.native.NativeTouchEventManager;
#end