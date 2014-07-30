package lime.graphics.opengl; #if !js


class GLRenderbuffer extends GLObject {
	
	
	private override function getType ():String {
		
		return "Renderbuffer";
		
	}
    
    
}


#else
typedef GLRenderbuffer = js.html.webgl.Renderbuffer;
#end