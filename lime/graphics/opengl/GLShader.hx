package lime.graphics.opengl; #if (!js || !html5 || display)


class GLShader extends GLObject {
	
	
	private override function getType ():String {
		
		return "Shader";
		
	}
    
    
}


#else
typedef GLShader = js.html.webgl.Shader;
#end