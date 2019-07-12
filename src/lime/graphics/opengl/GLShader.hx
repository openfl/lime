package lime.graphics.opengl;

#if (!lime_doc_gen || lime_opengl || lime_opengles || lime_webgl)
#if !doc_gen
import lime.graphics.opengl.GL;
import lime.graphics.WebGLRenderContext;
import lime.utils.Log;

#if !lime_webgl
@:forward(id) abstract GLShader(GLObject) from GLObject to GLObject
{
#else
@:forward() abstract GLShader(js.html.webgl.Shader) from js.html.webgl.Shader to js.html.webgl.Shader
{
#end

#if !lime_webgl
@:from private static function fromInt(id:Int):GLShader
{
	return GLObject.fromInt(SHADER, id);
}
#end

public static function fromSource(gl:WebGLRenderContext, source:String, type:Int):GLShader
{
	var shader = gl.createShader(type);
	gl.shaderSource(shader, source);
	gl.compileShader(shader);

	if (gl.getShaderParameter(shader, gl.COMPILE_STATUS) == 0)
	{
		var message;

		if (type == gl.VERTEX_SHADER) message = "Error compiling vertex shader";
		else if (type == gl.FRAGMENT_SHADER) message = "Error compiling fragment shader";
		else
			message = "Error compiling unknown shader type";

		message += "\n" + gl.getShaderInfoLog(shader);
		Log.error(message);
	}

	return shader;
}
}
#else
@:forward abstract GLShader(Dynamic) from Dynamic to Dynamic
{
	public static function fromSources(gl:Dynamic, source:String, type:Int):GLShader
	{
		return null;
	}
}
#end
#end
