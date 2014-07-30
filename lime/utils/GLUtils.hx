package lime.utils;


import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLShader;
import lime.graphics.opengl.GL;


class GLUtils {
	
	
	public static function compileShader (source:String, type:Int):GLShader {
		
		var shader = GL.createShader (type);
		GL.shaderSource (shader, source);
		GL.compileShader (shader);
		
		if (GL.getShaderParameter (shader, GL.COMPILE_STATUS) == 0) {
			
			switch (type) {
				
				case GL.VERTEX_SHADER: throw "Error compiling vertex shader";
				case GL.FRAGMENT_SHADER: throw "Error compiling fragment shader";
				default: throw "Error compiling unknown shader type";
				
			}
			
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
			
			throw "Unable to initialize the shader program.";
			
		}
		
		return program;
		
	}
	
	
}