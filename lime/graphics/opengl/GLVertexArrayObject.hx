package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLVertexArrayObject extends GLObject {
	
	
	private override function getType ():String {
		
		return "VertexArrayObject";
		
	}
    
    
}


#else


@:native("WebGLVertexArrayObject")
extern class GLVertexArrayObject {
	
	
	
	
	
}


#end