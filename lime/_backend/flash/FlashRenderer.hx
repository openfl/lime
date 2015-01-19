package lime._backend.flash;


import flash.Lib;
import lime.app.Application;
import lime.graphics.Renderer;

@:access(lime.app.Application)


class FlashRenderer {
	
	
	private var parent:Renderer;
	
	
	public function new (parent:Renderer) {
		
		this.parent = parent;
		
	}
	
	
	public function create ():Void {
		
		parent.context = FLASH (Lib.current);
		
	}
	
	
	public function flip ():Void {
		
		
		
	}
	
	
	public static function render ():Void {
		
		for (window in Application.__instance.windows) {
			
			if (window.currentRenderer != null) {
				
				window.currentRenderer.backend.renderEvent ();
				
			}
			
		}
		
	}
	
	
	private function renderEvent ():Void {
		
		if (!Application.__initialized) {
			
			Application.__initialized = true;
			Application.__instance.init (parent.context);
			
		}
		
		Application.__instance.render (parent.context);
		Renderer.onRender.dispatch (parent.context);
		
		flip ();
		
	}
	
	
}