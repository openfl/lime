package lime.graphics.opengl.ext;

#if (js && html5)
import lime.graphics.opengl.GLShader;

@:keep
@:native("WEBGL_depth_texture")
@:noCompletion extern class WEBGL_depth_texture
{
	public var UNSIGNED_INT_24_8_WEBGL:Int;
}
#end
