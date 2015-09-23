package lime.audio.openal;


import lime.system.CFFIPointer;

@:allow(lime.audio.openal.AL)
@:allow(lime.audio.openal.ALC)


abstract ALContext(CFFIPointer) from CFFIPointer to CFFIPointer {
	
	
	private function new (handle:CFFIPointer) {
		
		this = handle;
		
	}
	
	
}