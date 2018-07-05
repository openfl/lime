package lime.graphics.opengl; #if lime_opengl


import lime.graphics.opengl.GL;
import lime.graphics.WebGLRenderContext;
import lime.utils.Log;


#if (!js || !html5 || display)
@:forward(id) abstract GLShader(GLObject) from GLObject to GLObject {
#else
@:forward() abstract GLShader(js.html.webgl.Shader) from js.html.webgl.Shader to js.html.webgl.Shader {
#end
	
	
	#if (!js || !html5 || display)
	@:from private static function fromInt (id:Int):GLShader {
		
		return GLObject.fromInt (SHADER, id);
		
	}
	#end
	
	
	public static function fromSource (gl:WebGLRenderContext, source:String, type:Int):GLShader {
		
		var shader = gl.createShader (type);
		gl.shaderSource (shader, source);
		gl.compileShader (shader);
		
		if (gl.getShaderParameter (shader, gl.COMPILE_STATUS) == 0) {
			
			var message;
			
			if (type == gl.VERTEX_SHADER) message = "Error compiling vertex shader";
			else if (type == gl.FRAGMENT_SHADER) message = "Error compiling fragment shader";
			else message = "Error compiling unknown shader type";
			
			message += "\n" + gl.getShaderInfoLog (shader);
			Log.error (message);
			
		}
		
		return shader;
		
	}
	
	
}


#else
typedef GLShader = Dynamic;
#end