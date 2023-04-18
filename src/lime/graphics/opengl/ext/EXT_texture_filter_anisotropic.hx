package lime.graphics.opengl.ext;

@:keep
#if (!js || !html5 || display)
@:noCompletion class EXT_texture_filter_anisotropic
{
	public var TEXTURE_MAX_ANISOTROPY_EXT = 0x84FE;
	public var MAX_TEXTURE_MAX_ANISOTROPY_EXT = 0x84FF;

	@:noCompletion private function new() {}
}
#else
@:native("EXT_texture_filter_anisotropic")
@:noCompletion extern class EXT_texture_filter_anisotropic
{
	public var TEXTURE_MAX_ANISOTROPY_EXT:Int;
	public var MAX_TEXTURE_MAX_ANISOTROPY_EXT:Int;
}
#end
