package lime.graphics.opengl.ext;

#if (js && html5)
@:keep
@:native("WEBGL_compressed_texture_pvrtc")
@:noCompletion extern class WEBGL_compressed_texture_pvrtc
{
	public var COMPRESSED_RGB_PVRTC_4BPPV1_IMG:Int;
	public var COMPRESSED_RGBA_PVRTC_4BPPV1_IMG:Int;
	public var COMPRESSED_RGB_PVRTC_2BPPV1_IMG:Int;
	public var COMPRESSED_RGBA_PVRTC_2BPPV1_IMG:Int;
}
#end
