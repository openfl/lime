package lime.graphics.opengl.ext;

@:keep
#if (!js || !html5 || display)
@:noCompletion class EXT_shader_texture_lod
{
	@:noCompletion private function new() {}
}
#else
@:native("EXT_shader_texture_lod")
@:noCompletion extern class EXT_shader_texture_lod {}
#end
