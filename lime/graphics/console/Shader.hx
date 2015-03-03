package lime.graphics.console; #if lime_console


import lime.ConsoleIncludePaths;


@:include("ConsoleHaxeAPI.h")
@:native("lime::hxapi::ConsoleShader")
extern class Shader {

	
}


#else


abstract Shader(Int) {
	
	
	public function new (name:String):Void {
		
		this = 0;
		
	}


}


#end
