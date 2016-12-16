package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLRenderbuffer extends GLObject {
	
	
	private override function getType ():String {
		
		return "Renderbuffer";
		
	}
    
    
}


#else
typedef GLRenderbuffer = js.html.webgl.Renderbuffer;
#end