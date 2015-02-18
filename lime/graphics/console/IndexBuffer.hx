package lime.graphics.console; #if lime_console


import cpp.UInt8;
import cpp.UInt16;
import cpp.Pointer;
import cpp.RawConstPointer;
import haxe.io.Input;
import lime.ConsoleIncludePaths;


// TODO(james4k): use abstract type instead when @:headerCode is supported
@:headerCode("#include <ConsoleIndexBuffer.h>")
class IndexBuffer {


	private var ptr:RawConstPointer<UInt8>;


	public function new (indices:Array<UInt16>):Void {

		this.ptr = untyped __cpp__ (
			"(uint8_t *)lime::console_indexbuffer::New ({0}, {1})",
			Pointer.arrayElem (indices, 0),
			indices.length
		);

	}

	
}


#else


abstract IndexBuffer(Int) {
	
	
	public function new (indices:Array<Int>):Void {
		
		this = 0;
		
	}


}


#end
