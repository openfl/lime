package lime.media.openal; #if !hl


import lime.system.CFFIPointer;

@:allow(lime.media.openal.AL)
@:allow(lime.media.openal.ALC)


abstract ALDevice(CFFIPointer) from CFFIPointer to CFFIPointer {
	
	
	private inline function new (handle:CFFIPointer) {
		
		this = handle;
		
	}
	
	
}


#else
typedef ALDevice = hl.Abstract<"alc_device">;
#end