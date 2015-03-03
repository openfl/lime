package lime.graphics.console; #if lime_console


import lime.ConsoleIncludePaths;


@:include("ConsoleHaxeAPI.h")
@:native("lime::hxapi::ConsoleIndexBuffer")
extern class IndexBuffer {



}


#else


abstract IndexBuffer(Int) {
	
	
	public function new (indices:Array<Int>):Void {
		
		this = 0;
		
	}


}


#end
