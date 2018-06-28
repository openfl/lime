package lime.graphics.opengl; #if lime_opengl #if (!js || !html5 || display)


import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;

@:access(lime._internal.backend.native.NativeCFFI)


abstract GLSync(CFFIPointer) from CFFIPointer to CFFIPointer {
	
	
	
}


#else
@:native("WebGLSync")
extern class GLSync {}
#end
#else
typedef GLSync = Dynamic;
#end