package lime.media.openal; #if (!lime_doc_gen || lime_openal)


import lime.system.CFFIPointer;

@:allow(lime.media.openal.AL)


abstract ALBuffer(CFFIPointer) from CFFIPointer to CFFIPointer {
	
	
	private inline function new (handle:CFFIPointer) {
		
		this = handle;
		
	}
	
	
}


#end