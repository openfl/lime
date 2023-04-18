package lime.graphics.opengl.ext;

@:keep
#if (!js || !html5 || display)
@:noCompletion class EXT_sRGB
{
	public var SRGB_EXT = 0x8C40;
	public var SRGB_ALPHA_EXT = 0x8C42;
	public var SRGB8_ALPHA8_EXT = 0x8C43;
	public var FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT = 0x8210;

	@:noCompletion private function new() {}
}
#else
@:native("EXT_sRGB")
@:noCompletion extern class EXT_sRGB
{
	public var SRGB_EXT:Int;
	public var SRGB_ALPHA_EXT:Int;
	public var SRGB8_ALPHA8_EXT:Int;
	public var FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT:Int;
}
#end
