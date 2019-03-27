package lime.graphics.opengl.ext;

#if (js && html5)
@:keep
@:native("WEBGL_compressed_texture_s3tc")
@:noCompletion extern class WEBGL_compressed_texture_s3tc
{
	public var COMPRESSED_RGB_S3TC_DXT1_EXT:Int;
	public var COMPRESSED_RGBA_S3TC_DXT1_EXT:Int;
	public var COMPRESSED_RGBA_S3TC_DXT3_EXT:Int;
	public var COMPRESSED_RGBA_S3TC_DXT5_EXT:Int;
}
#end
