package lime.app;


#if flash
import flash.display.LoaderInfo;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.ProgressEvent;
import flash.Lib;
#end


class Preloader #if flash extends Sprite #end {
	
	
	public var complete:Bool;
	public var onComplete:Dynamic;
	
	
	public function new () {
		
		#if flash
		super ();
		#end
		
	}
	
	
	public function create (config:Config):Void {
		
		#if flash
		Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		
		Lib.current.addChild (this);
		
		Lib.current.loaderInfo.addEventListener (Event.COMPLETE, loaderInfo_onComplete);
		Lib.current.loaderInfo.addEventListener (Event.INIT, loaderInfo_onInit);
		Lib.current.loaderInfo.addEventListener (ProgressEvent.PROGRESS, loaderInfo_onProgress);
		Lib.current.addEventListener (Event.ENTER_FRAME, current_onEnter);
		#end
		
		#if !flash
		start ();
		#end
		
	}
	
	
	private function start ():Void {
		
		#if flash
		if (Lib.current.contains (this)) {
			
			Lib.current.removeChild (this);
			
		}
		#end
		
		if (onComplete != null) {
			
			onComplete ();
			
		}
		
	}
	
	
	private function update ():Void {
		
		
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	#if flash
	private function current_onEnter (event:Event):Void {
		
		if (complete) {
			
			Lib.current.removeEventListener (Event.ENTER_FRAME, current_onEnter);
			Lib.current.loaderInfo.removeEventListener (Event.COMPLETE, loaderInfo_onComplete);
			Lib.current.loaderInfo.removeEventListener (Event.INIT, loaderInfo_onInit);
			Lib.current.loaderInfo.removeEventListener (ProgressEvent.PROGRESS, loaderInfo_onProgress);
			
			start ();
			
		}
		
	}
	
	
	private function loaderInfo_onComplete (event:flash.events.Event):Void {
		
		complete = true;
		update ();
		
	}
	
	
	private function loaderInfo_onInit (event:flash.events.Event):Void {
		
		update ();
		
	}
	
	
	private function loaderInfo_onProgress (event:flash.events.ProgressEvent):Void {
		
		update ();
		
	}
	#end
	
	
}