package lime.graphics.console; #if lime_console


import lime.graphics.console.VertexOutput;
import lime.ConsoleIncludePaths;


@:include("ConsoleHaxeAPI.h")
@:native("lime::hxapi::ConsoleVertexBuffer")
extern class VertexBuffer {

	public function lock ():VertexOutput;
	public function unlock ():Void;
	
}


#else


import lime.graphics.console.VertexOutput;


class VertexBuffer {

	public function new () {}
	
	public function lock ():VertexOutput { return new VertexOutput (); }
	public function unlock ():Void {}

}


#end
