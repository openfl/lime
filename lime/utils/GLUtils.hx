package lime.utils;


import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLShader;
import lime.graphics.opengl.GL;
import lime.utils.Log;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLUtils {
	
	
	public static function compileShader (source:String, type:Int):GLShader {
		
		var shader = GL.createShader (type);
		GL.shaderSource (shader, source);
		GL.compileShader (shader);
		
		if (GL.getShaderParameter (shader, GL.COMPILE_STATUS) == 0) {
			
			var message = switch (type) {
				
				case GL.VERTEX_SHADER: "Error compiling vertex shader";
				case GL.FRAGMENT_SHADER: "Error compiling fragment shader";
				default: "Error compiling unknown shader type";
				
			}
			
			message += "\n" + GL.getShaderInfoLog (shader);
			Log.error (message);
			
		}
		
		return shader;
		
	}
	
	
	public static function createProgram (vertexSource:String, fragmentSource:String):GLProgram {
		
		var vertexShader = compileShader (vertexSource, GL.VERTEX_SHADER);
		var fragmentShader = compileShader (fragmentSource, GL.FRAGMENT_SHADER);
		
		var program = GL.createProgram ();
		GL.attachShader (program, vertexShader);
		GL.attachShader (program, fragmentShader);
		GL.linkProgram (program);
		
		if (GL.getProgramParameter (program, GL.LINK_STATUS) == 0) {
			
			var message = "Unable to initialize the shader program";
			message += "\n" + GL.getProgramInfoLog (program);
			Log.error (message);
			
		}
		
		return program;
		
	}
	
	
}