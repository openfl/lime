package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLTexture extends GLObject {
	
	
	private override function getType ():String {
		
		return "Texture";
		
	}
    
    
}


#else
typedef GLTexture = js.html.webgl.Texture;
#end