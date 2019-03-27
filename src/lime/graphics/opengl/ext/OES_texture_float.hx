package lime.graphics.opengl.ext;

#if (!js || !html5 || display)
@:noCompletion class OES_texture_float
{
	@:noCompletion private function new() {}
}
#else
@:native("OES_texture_float")
@:noCompletion extern class OES_texture_float {}
#end
