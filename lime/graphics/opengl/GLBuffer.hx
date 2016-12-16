package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLBuffer extends GLObject {
	
	
	private override function getType ():String {
		
		return "Buffer";
		
	}
	
	
}


#else
typedef GLBuffer = js.html.webgl.Buffer;
#end