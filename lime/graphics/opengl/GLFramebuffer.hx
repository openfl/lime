package lime.graphics.opengl;
#if js
typedef GLFramebuffer = js.html.webgl.Framebuffer;
#else


class GLFramebuffer extends GLObject {
	
	
	private override function getType ():String {
		
		return "Framebuffer";
		
	}
	
	
}


#end