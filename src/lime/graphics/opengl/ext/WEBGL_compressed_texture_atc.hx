package lime.graphics.opengl.ext;

#if (js && html5)
@:keep
@:native("WEBGL_compressed_texture_atc")
@:noCompletion extern class WEBGL_compressed_texture_atc
{
	public var COMPRESSED_RGB_ATC_WEBGL:Int;
	public var COMPRESSED_RGBA_ATC_EXPLICIT_ALPHA_WEBGL:Int;
	public var COMPRESSED_RGBA_ATC_INTERPOLATED_ALPHA_WEBGL:Int;
}
#end
