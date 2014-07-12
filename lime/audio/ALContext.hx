package lime.audio;


@:allow(lime.audio.AL)
@:allow(lime.audio.ALC)


abstract ALContext(Null<Float>) from Null<Float> to Null<Float> {
	
	
	private function new (handle:Float) {
		
		this = handle;
		
	}
	
	
}