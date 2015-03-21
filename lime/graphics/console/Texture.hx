package lime.graphics.console; #if lime_console


import lime.ConsoleIncludePaths;


@:include("ConsoleHaxeAPI.h")
@:native("lime::hxapi::ConsoleTexture")
extern class Texture {
	
	// valid returns true if this represents a non-zero handle to a texture.
	public var valid (get, never):Bool;

	private function get_valid ():Bool;

}


#else


class Texture {

	public function new () {}

}


#end
