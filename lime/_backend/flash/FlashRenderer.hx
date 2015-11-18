package lime._backend.flash;


import flash.Lib;
import lime.graphics.Renderer;


class FlashRenderer {
	
	
	private var parent:Renderer;
	
	
	public function new (parent:Renderer) {
		
		this.parent = parent;
		
	}
	
	
	public function create ():Void {
		
		parent.context = FLASH (Lib.current);
		parent.type = FLASH;
		
	}
	
	
	public function flip ():Void {
		
		
		
	}
	
	
	public function render ():Void {
		
		
		
	}
	
	
}