package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLQuery extends GLObject {
	
	
	private override function getType ():String {
		
		return "Query";
		
	}
    
    
}


#else


@:native("WebGLQuery")
extern class GLQuery {
	
	
	
	
	
}


#end