package lime.media.openal;


@:allow(lime.media.openal.AL)
@:allow(lime.media.openal.ALC)


abstract ALContext(Null<Float>) from Null<Float> to Null<Float> {
	
	
	private function new (handle:Float) {
		
		this = handle;
		
	}
	
	
}