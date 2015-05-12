package lime._backend.flash;


import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.Lib;
import lime.app.Application;
import lime.graphics.Image;
import lime.ui.Window;


class FlashWindow {
	
	
	private var enableTextEvents:Bool;
	private var parent:Window;
	
	
	public function new (parent:Window) {
		
		this.parent = parent;
		
	}
	
	
	public function close ():Void {
		
		
		
	}
	
	
	public function create (application:Application):Void {
		
		Lib.current.stage.align = StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		
	}
	
	
	public function getEnableTextEvents ():Bool {
		
		return enableTextEvents;
		
	}
	
	
	public function move (x:Int, y:Int):Void {
		
		
		
	}
	
	
	public function resize (width:Int, height:Int):Void {
		
		
		
	}
	
	
	public function setEnableTextEvents (value:Bool):Bool {
		
		return enableTextEvents = value;
		
	}
	
	
	public function setFullscreen (value:Bool):Bool {
		
		return value;
		
	}
	
	
	public function setIcon (image:Image):Void {
		
		
		
	}
	
	
	public function setMinimized (value:Bool):Bool {
		
		return false;
		
	}
	
	
}