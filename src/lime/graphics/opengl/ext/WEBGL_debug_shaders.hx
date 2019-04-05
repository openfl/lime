package lime.graphics.opengl.ext;

#if (js && html5)
import lime.graphics.opengl.GLShader;

@:keep
@:native("WEBGL_debug_shaders")
@:noCompletion extern class WEBGL_debug_shaders
{
	public function getTranslatedShaderSource(shader:GLShader):String;
}
#end
