package lime.graphics.opengl; #if (!js || !html5 || display)


import lime.graphics.opengl.GL;

@:forward(id)


abstract GLSampler(GLObject) from GLObject to GLObject {
	
	
	@:from private static function fromInt (id:Int):GLSampler {
		
		return GLObject.fromInt (SAMPLER, id);
		
	}
	
	
}


#else
@:native("WebGLSampler")
extern class GLSampler {}
#end