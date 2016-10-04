package lime.audio.openal;


import lime.system.CFFIPointer;

@:allow(lime.audio.openal.AL)


abstract ALSource(CFFIPointer) from CFFIPointer to CFFIPointer {
	
	
	private inline function new (handle:CFFIPointer) {
		
		this = handle;
		
	}
	
	
}