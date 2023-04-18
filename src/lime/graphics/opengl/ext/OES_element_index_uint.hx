package lime.graphics.opengl.ext;

@:keep
#if (!js || !html5 || display)
@:noCompletion class OES_element_index_uint
{
	public var UNSIGNED_INT = 0x1405;

	@:noCompletion private function new() {}
}
#else
@:native("OES_element_index_uint")
@:noCompletion extern class OES_element_index_uint {}
#end
