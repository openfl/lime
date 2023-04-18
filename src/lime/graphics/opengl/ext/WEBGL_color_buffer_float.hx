package lime.graphics.opengl.ext;

#if (js && html5)
@:keep
@:native("WEBGL_color_buffer_float")
@:noCompletion extern class WEBGL_color_buffer_float
{
	public var RGBA32F_EXT:Int;
	public var RGB32F_EXT:Int;
	public var FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE_EXT:Int;
	public var UNSIGNED_NORMALIZED_EXT:Int;
}
#end
