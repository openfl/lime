package lime.graphics.opengl; #if lime_opengl


import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLShader;
import lime.graphics.WebGLRenderContext;
import lime.utils.Log;


#if (!js || !html5 || display)
@:forward(id, refs) abstract GLProgram(GLObject) from GLObject to GLObject {
#else
@:forward() abstract GLProgram(js.html.webgl.Shader) from js.html.webgl.Program to js.html.webgl.Program {
#end
	
	
	#if (!js || !html5 || display)
	@:from private static function fromInt (id:Int):GLProgram {
		
		return GLObject.fromInt (PROGRAM, id);
		
	}
	#end
	
	
	public static function fromSources (gl:WebGLRenderContext, vertexSource:String, fragmentSource:String):GLProgram {
		
		var vertexShader = GLShader.fromSource (gl, vertexSource, gl.VERTEX_SHADER);
		var fragmentShader = GLShader.fromSource (gl, fragmentSource, gl.FRAGMENT_SHADER);
		
		var program = gl.createProgram ();
		gl.attachShader (program, vertexShader);
		gl.attachShader (program, fragmentShader);
		gl.linkProgram (program);
		
		if (gl.getProgramParameter (program, GL.LINK_STATUS) == 0) {
			
			var message = "Unable to initialize the shader program";
			message += "\n" + GL.getProgramInfoLog (program);
			Log.error (message);
			
		}
		
		return program;
		
	}
	
	
}


#else
typedef GLProgram = Dynamic;
#end