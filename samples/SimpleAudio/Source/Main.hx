package;


import lime.app.Application;
import lime.audio.AudioSource;
import lime.graphics.RenderContext;
import lime.Assets;


class Main extends Application {
	
	
	private var ambience:AudioSource;
	private var sound:AudioSource;
	
	
	public function new () {
		
		super ();
		
	}
	
	
	public override function init (_):Void {
		
		#if !flash
		ambience = new AudioSource (Assets.getAudioBuffer ("assets/ambience.ogg"));
		ambience.play ();
		#end
		
		sound = new AudioSource (Assets.getAudioBuffer ("assets/sound.wav"));
		
	}
	
	
	public override function onMouseDown (_, _, _):Void {
		
		sound.play ();
		
	}
	
	
	public override function render (context:RenderContext):Void {
		
		switch (context) {
			
			case CANVAS (context):
				
				context.fillStyle = "#3CB878";
				context.fillRect (0, 0, window.width, window.height);
			
			case DOM (element):
				
				element.style.backgroundColor = "#3CB878";
			
			case FLASH (sprite):
				
				sprite.graphics.beginFill (0x3CB878);
				sprite.graphics.drawRect (0, 0, window.width, window.height);
			
			case OPENGL (gl):
				
				gl.viewport (0, 0, window.width, window.height);
				gl.clearColor (60 / 255, 184 / 255, 7 / 255, 1);
				gl.clear (gl.COLOR_BUFFER_BIT);
				
			default:
			
		}
		
	}
	
	
}