package lime.graphics.console; #if lime_console


import cpp.Pointer;
import cpp.UInt8;
import lime.ConsoleIncludePaths;
import lime.system.System;
import lime.utils.ByteArray;


@:include("ConsoleTextureData.h")
@:native("cpp::Struct<lime::ConsoleTextureData>")
extern class TextureData {


	// valid returns true if this represents a non-zero handle to texture data.
	public var valid (get, never):Bool;

	public var width (get, never):Int;
	public var height (get, never):Int;


	// fromFile loads texture data from the named file.
	@:native("lime::ConsoleTextureData::fromFile")
	public static function fromFile (name:String):TextureData;

	// decode does any decompression or whatever is necessary to output lime's
	// standard RGBA.
	public function decode (dest:Pointer<UInt8>, destSize:Int):Void;

	// release releases the texture data.
	public function release ():Void;


	private function get_valid ():Bool;
	private function get_width ():Int;
	private function get_height ():Int;


}


#end
