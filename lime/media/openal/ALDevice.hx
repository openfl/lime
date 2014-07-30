package lime.media.openal;


@:allow(lime.media.openal.AL)
@:allow(lime.media.openal.ALC)


abstract ALDevice(Null<Float>) from Null<Float> to Null<Float> {
	
	
	private function new (handle:Float) {
		
		this = handle;
		
	}
	
	
}