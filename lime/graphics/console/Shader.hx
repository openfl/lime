package lime.graphics.console; #if lime_console


import lime.ConsoleIncludePaths;


@:include("ConsoleHaxeAPI.h")
@:native("lime::hxapi::ConsoleShader")
extern class Shader {

	
}


#else


class Shader {
	
	public function new () {}

}


#end
