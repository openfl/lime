package lime.graphics.opengl.ext;

#if (js && html5)
@:keep
@:native("WEBGL_debug_renderer_info")
@:noCompletion extern class WEBGL_debug_renderer_info
{
	public var UNMASKED_VENDOR_WEBGL:Int;
	public var UNMASKED_RENDERER_WEBGL:Int;
}
#end
