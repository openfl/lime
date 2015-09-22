package lime.audio.openal;


@:allow(lime.audio.openal.AL)
@:allow(lime.audio.openal.ALC)


abstract ALDevice(Dynamic) {
	
	
	private function new (handle:Dynamic) {
		
		this = handle;
		
	}
	
	
}