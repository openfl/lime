package lime.graphics.opengl.ext;

@:keep
#if (!js || !html5 || display)
@:noCompletion class OES_standard_derivatives
{
	public var FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;

	@:noCompletion private function new() {}
}
#else
@:native("OES_standard_derivatives")
@:noCompletion extern class OES_standard_derivatives
{
	public var FRAGMENT_SHADER_DERIVATIVE_HINT_OES:Int;
}
#end
