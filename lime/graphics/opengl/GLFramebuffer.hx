package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLFramebuffer extends GLObject {
	
	
	private override function getType ():String {
		
		return "Framebuffer";
		
	}
	
	
}


#else
typedef GLFramebuffer = js.html.webgl.Framebuffer;
#end