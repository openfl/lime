package lime.graphics.opengl.ext;

@:keep
#if (!js || !html5 || display)
@:noCompletion class OES_texture_half_float
{
	public var HALF_FLOAT_OES = 0x8D61;

	@:noCompletion private function new() {}
}
#else
@:native("OES_texture_half_float")
@:noCompletion extern class OES_texture_half_float
{
	public var HALF_FLOAT_OES:Int;
}
#end
