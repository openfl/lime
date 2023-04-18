package lime.graphics.opengl.ext;

#if (!js || !html5 || display)
@:noCompletion class EXT_color_buffer_float
{
	@:noCompletion private function new() {}
}
#else
@:native("EXT_color_buffer_float")
@:noCompletion extern class EXT_color_buffer_float {}
#end
