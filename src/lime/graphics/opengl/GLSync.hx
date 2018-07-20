package lime.graphics.opengl; #if (!lime_doc_gen || lime_opengl || lime_opengles || lime_webgl)
#if ((lime_opengl || lime_opengles) && !display)


import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;

@:access(lime._internal.backend.native.NativeCFFI)


abstract GLSync(CFFIPointer) from CFFIPointer to CFFIPointer {



}


#elseif (lime_webgl && !display)
@:native("WebGLSync")
extern class GLSync {}
#else
typedef GLSync = Dynamic;
#end
#end