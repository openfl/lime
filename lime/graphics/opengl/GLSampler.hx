package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLSampler extends GLObject {
	
	
	private override function getType ():String {
		
		return "Sampler";
		
	}
    
    
}


#else


@:native("WebGLSampler")
extern class GLSampler {
	
	
	
	
	
}


#end