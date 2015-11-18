package lime.graphics.console; #if lime_console


import cpp.UInt8;
import cpp.Pointer;
import lime.ConsoleIncludePaths;


@:include("ConsoleTexture.h")
@:native("cpp::Struct<lime::ConsoleTexture>")
extern class Texture {
	
	// valid returns true if this represents a non-zero handle to a texture.
	public var valid (get, never):Bool;

	public function update (data:TextureData):Void;
	public function updateFromRGBA (data:Pointer<UInt8>):Void;

	private function get_valid ():Bool;

}


#else


class Texture {

	public function new () {}

}


#end
