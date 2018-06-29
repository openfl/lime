package lime._internal.backend.flash;


import flash.ui.MultitouchInputMode;
import flash.ui.Multitouch;
import lime.app.Application;
import lime.app.Config;
import lime.media.AudioManager;

@:access(lime.app.Application)


class FlashApplication {
	
	
	private var parent:Application;
	
	
	public function new (parent:Application):Void {
		
		this.parent = parent;
		
		AudioManager.init ();
		
	}
	
	
	public function create (config:Config):Void {
		
		
		
	}
	
	
	public function exec ():Int {
		
		Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
		
		return 0;
		
	}
	
	
	public function exit ():Void {
		
		
		
	}
	
	
}
