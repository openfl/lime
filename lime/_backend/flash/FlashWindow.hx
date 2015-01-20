package lime._backend.flash;


import flash.events.Event;
import flash.events.FocusEvent;
import flash.Lib;
import lime.app.Application;
import lime.graphics.Image;
import lime.ui.KeyEventManager;
import lime.ui.MouseEventManager;
import lime.ui.TouchEventManager;
import lime.ui.Window;

@:access(lime.ui.KeyEventManager)
@:access(lime.ui.MouseEventManager)
@:access(lime.ui.TouchEventManager)


class FlashWindow {
	
	
	private var parent:Window;
	
	
	public function new (parent:Window) {
		
		this.parent = parent;
		
	}
	
	
	public function create (application:Application):Void {
		
		Lib.current.stage.addEventListener (Event.ACTIVATE, handleEvent);
		Lib.current.stage.addEventListener (Event.DEACTIVATE, handleEvent);
		Lib.current.stage.addEventListener (FocusEvent.FOCUS_IN, handleEvent);
		Lib.current.stage.addEventListener (FocusEvent.FOCUS_OUT, handleEvent);
		Lib.current.stage.addEventListener (Event.RESIZE, handleEvent);
		
	}
	
	
	private function handleEvent (event:Event):Void {
		
		switch (event.type) {
			
			case Event.ACTIVATE:
				
				Window.onWindowActivate.dispatch ();
			
			case Event.DEACTIVATE:
				
				Window.onWindowDeactivate.dispatch ();
			
			case FocusEvent.FOCUS_IN:
				
				Window.onWindowFocusIn.dispatch ();
			
			case FocusEvent.FOCUS_OUT:
				
				Window.onWindowFocusOut.dispatch ();
			
			default:
				
				parent.width = Lib.current.stage.stageWidth;
				parent.height = Lib.current.stage.stageHeight;
				
				Window.onWindowResize.dispatch (parent.width, parent.height);
			
		}
		
	}
	
	
	public function move (x:Int, y:Int):Void {
		
		
		
	}
	
	
	public function resize (width:Int, height:Int):Void {
		
		
		
	}
	
	
	public function setIcon (image:Image):Void {
		
		
		
	}
	
	
}