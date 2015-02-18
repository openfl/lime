package lime.graphics.console; #if lime_console


import cpp.Float32;
import cpp.UInt8;
import cpp.UInt32;
import cpp.RawConstPointer;
import lime.ConsoleIncludePaths;
import lime.math.Matrix4;


// TODO(james4k): use abstract type instead when @:headerCode is supported
@:headerCode("#include <ConsoleShader.h>")
class Shader {


	private var ptr:RawConstPointer<UInt8>;


	public function new (name:String):Void {

		this.ptr = untyped __cpp__ ("(uint8_t *)lime::console_shader::Find ({0})", name);

	}

	
}


#else


abstract Shader(Int) {
	
	
	public function new (name:String):Void {
		
		this = 0;
		
	}


}


#end
