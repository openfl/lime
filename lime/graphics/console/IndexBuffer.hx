package lime.graphics.console; #if lime_console


import cpp.Pointer;
import cpp.UInt16;
import lime.ConsoleIncludePaths;


@:include("ConsoleHaxeAPI.h")
@:native("lime::hxapi::ConsoleIndexBuffer")
extern class IndexBuffer {

	public function lock ():Pointer<UInt16>;
	public function unlock ():Void;

}


#else


class IndexBuffer {
	
	public function new () {}

}


#end
