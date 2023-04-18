package lime.graphics.opengl.ext;

#if (js && html5)
@:keep
@:native("WEBGL_compressed_texture_etc")
@:noCompletion extern class WEBGL_compressed_texture_etc
{
	public var COMPRESSED_R11_EAC:Int;
	public var COMPRESSED_SIGNED_R11_EAC:Int;
	public var COMPRESSED_RG11_EAC:Int;
	public var COMPRESSED_SIGNED_RG11_EAC:Int;
	public var COMPRESSED_RGB8_ETC2:Int;
	public var COMPRESSED_RGBA8_ETC2_EAC:Int;
	public var COMPRESSED_SRGB8_ETC2:Int;
	public var COMPRESSED_SRGB8_ALPHA8_ETC2_EAC:Int;
	public var COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2:Int;
	public var COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2:Int;
}
#end
