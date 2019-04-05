package lime.graphics.opengl.ext;

#if (!js || !html5 || display)
@:noCompletion class OES_texture_half_float_linear
{
	@:noCompletion private function new() {}
}
#else
@:native("OES_texture_half_float_linear")
@:noCompletion extern class OES_texture_half_float_linear {}
#end
