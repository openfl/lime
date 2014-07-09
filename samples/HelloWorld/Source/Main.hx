package;


import lime.app.Application;
import lime.graphics.RenderContext;


class Main extends Application {
	
	
	public function new () {
		
		super ();
		
		trace ("Hello World");
		
	}
	
	
	public override function render (context:RenderContext):Void {
		
		switch (context) {
			
			case CANVAS (context):
				
				context.fillStyle = "#BFFF00";
				context.fillRect (0, 0, window.width, window.height);
			
			case DOM (element):
				
				element.style.backgroundColor = "#BFFF00";
			
			case FLASH (sprite):
				
				sprite.graphics.beginFill (0xBFFF00);
				sprite.graphics.drawRect (0, 0, window.width, window.height);
			
			case OPENGL (gl):
				
				gl.clearColor (0.75, 1, 0, 1);
				gl.clear (gl.COLOR_BUFFER_BIT);
				
			default:
			
		}
		
	}
	
	
}