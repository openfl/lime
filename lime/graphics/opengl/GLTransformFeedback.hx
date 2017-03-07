package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLTransformFeedback extends GLObject {
	
	
	private override function getType ():String {
		
		return "TransformFeedback";
		
	}
    
    
}


#else


@:native("WebGLTransformFeedback")
extern class GLTransformFeedback {
	
	
	
	
	
}


#end