package lime._backend.flash;


import flash.events.Event;
import flash.ui.MultitouchInputMode;
import flash.ui.Multitouch;
import flash.Lib;
import lime.app.Application;
import lime.app.Config;
import lime.media.AudioManager;
import lime.ui.Window;

@:access(lime.app.Application)


class FlashApplication {
	
	
	private var cacheTime:Int;
	private var parent:Application;
	
	
	public function new (parent:Application):Void {
		
		this.parent = parent;
		
		Lib.current.stage.frameRate = 60;
		AudioManager.init ();
		
	}
	
	
	public function create (config:Config):Void {
		
		
		
	}
	
	
	public function exec ():Int {
		
		Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
		
		cacheTime = Lib.getTimer ();
		handleApplicationEvent (null);
		
		Lib.current.stage.addEventListener (Event.ENTER_FRAME, handleApplicationEvent);
		
		return 0;
		
	}
	
	
	public function exit ():Void {
		
		
		
	}
	
	
	public function getFrameRate ():Float {
		
		return Lib.current.stage.frameRate;
		
	}
	
	
	private function handleApplicationEvent (event:Event):Void {
		
		var currentTime = Lib.getTimer ();
		var deltaTime = currentTime - cacheTime;
		cacheTime = currentTime;
		
		parent.onUpdate.dispatch (deltaTime);
		
		if (parent.window != null) {
			
			parent.window.onRender.dispatch ();
			
		}
		
	}
	
	
	public function setFrameRate (value:Float):Float {
		
		if (parent.windows.length > 0) {
			
			for (window in parent.windows) {
				
				window.stage.frameRate = value;
				
			}
			
		} else {
			
			Lib.current.stage.frameRate = value;
			
		}
		
		return value;
		
	}
	
	
}
