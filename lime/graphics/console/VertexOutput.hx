package lime.graphics.console; #if lime_console


import cpp.Float32;
import cpp.UInt8;
import lime.ConsoleIncludePaths;


@:include("ConsoleVertexOutput.h")
@:native("cpp::Struct<lime::ConsoleVertexOutput>")
extern class VertexOutput {

	public function vec2 (x:Float32, y:Float32):Void;
	public function vec3 (x:Float32, y:Float32, z:Float32):Void;
	public function color (r:UInt8, g:UInt8, b:UInt8, a:UInt8):Void;

}


#else


class VertexOutput {

	public function new () {}

	public function vec2 (x, y):Void {}
	public function vec3 (x, y, z):Void {}
	public function color (r, g, b, a):Void {}

}


#end

