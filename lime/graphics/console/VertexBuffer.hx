package lime.graphics.console; #if lime_console


import cpp.Float32;
import cpp.UInt8;
import cpp.RawConstPointer;
import haxe.io.Input;
import lime.ConsoleIncludePaths;


@:enum abstract VertexDecl(Int) {

	var PositionColor = 13; // xyz [3]float32, rgba [4]uint8

}


@:include("ConsoleVertexOutput.h")
@:native("lime::HxConsoleVertexOutput")
extern class VertexOutput {

	public function vec3 (x:Float32, y:Float32, z:Float32):Void;
	public function color (r:UInt8, g:UInt8, b:UInt8, a:UInt8):Void;

}


/*
// TODO(james4k): use abstract type instead when @:headerCode is supported
@:unreflective
@:structAccess
@:include("ConsoleVertexBuffer.h")
@:native("lime::ConsoleVertexBuffer")
extern class VertexBuffer {


	public function new (decl:VertexDecl, count:Int):Void;

	public function lock ():VertexOutput;
	public function unlock ():Void;

	
}
*/


// TODO(james4k): use abstract type instead when @:headerCode is supported
//@:unreflective
@:headerCode("#include <ConsoleVertexBuffer.h>")
class VertexBuffer {


	private var ptr:RawConstPointer<UInt8>;


	public function new (decl:VertexDecl, count:Int):Void {

		this.ptr = untyped __cpp__ (
			"(uint8_t *)lime::console_vertexbuffer::New ({0}, {1})",
			decl,
			count
		);

	}


	public function lock ():VertexOutput {

		untyped __cpp__ (
			"uint8_t *dest = (uint8_t *)lime::console_vertexbuffer::Lock ((void *){0})",
			ptr
		);

		// TODO(james4k): VertexOutput output should do bounds checking
		return untyped __cpp__ (
			"ConsoleVertexOutput (dest)",
			ptr
		);

	}


	public function unlock ():Void {

		untyped __cpp__ (
			"lime::console_vertexbuffer::Unlock ((void *){0})",
			ptr
		);
	}

	
}


#else


abstract VertexBuffer(Int) {
	
	
	public function new ():Void {
		
		this = 0;
		
	}


}


#end
