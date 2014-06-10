package lime.graphics.opengl;
#if js
typedef GLRenderbuffer = js.html.webgl.Renderbuffer;
#else


class GLRenderbuffer extends GLObject {
	
	
	private override function getType ():String {
		
		return "Renderbuffer";
		
	}
    
    
}


#end