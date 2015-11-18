package lime.graphics.console; #if lime_console


import lime.ConsoleIncludePaths;


@:include("ConsoleShader.h")
@:native("cpp::Struct<lime::ConsoleShader>")
extern class Shader {

	
}


#else


class Shader {
	
	public function new () {}

}


#end
