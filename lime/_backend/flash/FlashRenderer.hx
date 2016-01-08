package lime._backend.flash;


import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.Lib;
import lime.graphics.Image;
import lime.graphics.Renderer;
import lime.math.Rectangle;


class FlashRenderer {
	
	
	private var parent:Renderer;
	
	
	public function new (parent:Renderer) {
		
		this.parent = parent;
		
	}
	
	
	public function create ():Void {
		
		parent.context = FLASH (cast Lib.current);
		parent.type = FLASH;
		
	}
	
	
	public function flip ():Void {
		
		
		
	}
	
	
	public function readPixels (rect:Rectangle):Image {
		
		if (rect == null) {
			
			rect = new Rectangle (0, 0, parent.window.stage.stageWidth, parent.window.stage.stageHeight);
			
		} else {
			
			rect.__contract (0, 0, parent.window.stage.stageWidth, parent.window.stage.stageHeight);
			
		}
		
		if (rect.width > 0 && rect.height > 0) {
			
			var bitmapData = new BitmapData (Std.int (rect.width), Std.int (rect.height));
			
			var matrix = new Matrix ();
			matrix.tx = -rect.x;
			matrix.ty = -rect.y;
			
			bitmapData.draw (parent.window.stage, matrix);
			
			return Image.fromBitmapData (bitmapData);
			
		} else {
			
			return null;
			
		}
		
	}
	
	
	public function render ():Void {
		
		
		
	}
	
	
}