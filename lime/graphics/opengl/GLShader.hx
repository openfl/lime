package lime.graphics.opengl;
#if js
typedef GLShader = js.html.webgl.Shader;
#else


class GLShader extends GLObject {
	
	
	private override function getType ():String {
		
		return "Shader";
		
	}
    
    
}


#end