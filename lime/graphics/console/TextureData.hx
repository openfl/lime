package lime.graphics.console; #if lime_console


import cpp.Pointer;
import cpp.UInt8;
import lime.ConsoleIncludePaths;
import lime.system.System;
import lime.utils.ByteArray;


@:include("ConsoleHaxeAPI.h")
@:native("lime::hxapi::ConsoleTextureData")
extern class TextureData {


	// valid returns true if this represents a non-zero handle to texture data.
	public var valid (get, never):Bool;

	public var width (get, never):Int;
	public var height (get, never):Int;

	public var pointer (get, never):Pointer<UInt8>;


	// fromFile loads texture data from the named file.
	@:native("lime::ConsoleTextureData::fromFile")
	public static function fromFile (name:String):TextureData;


	// release releases the texture data.
	public function release ():Void;


	private function get_valid ():Bool;
	private function get_width ():Int;
	private function get_height ():Int;
	private function get_pointer ():Pointer<UInt8>;


}


#end
