package lime.graphics.opengl.ext;

@:keep
#if (!js || !html5 || display)
@:noCompletion class EXT_color_buffer_half_float
{
	public var RGBA16F_EXT = 0x881A;
	public var RGB16F_EXT = 0x881B;
	#if (!js && !html5)
	public var RG16F_EXT = 0x822F;
	public var R16F_EXT = 0x822D;
	#end
	public var FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE_EXT = 0x8211;
	public var UNSIGNED_NORMALIZED_EXT = 0x8C17;

	@:noCompletion private function new() {}
}
#else
@:native("EXT_color_buffer_half_float")
@:noCompletion extern class EXT_color_buffer_half_float
{
	public var RGBA16F_EXT:Int;
	public var RGB16F_EXT:Int;
	public var FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE_EXT:Int;
	public var UNSIGNED_NORMALIZED_EXT:Int;
}
#end
