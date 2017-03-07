package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLSync extends GLObject {
	
	
	private override function getType ():String {
		
		return "Sync";
		
	}
    
    
}


#else


@:native("WebGLSync")
extern class GLSync {
	
	
	
	
	
}


#end