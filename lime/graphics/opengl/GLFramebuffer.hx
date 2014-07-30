package lime.graphics.opengl; #if !js


class GLFramebuffer extends GLObject {
	
	
	private override function getType ():String {
		
		return "Framebuffer";
		
	}
	
	
}


#else
typedef GLFramebuffer = js.html.webgl.Framebuffer;
#end