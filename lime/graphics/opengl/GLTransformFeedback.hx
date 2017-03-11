package lime.graphics.opengl; #if (!js || !html5 || display)


import lime.graphics.opengl.GL;


abstract GLTransformFeedback(GLObject) from GLObject to GLObject {
	
	
	@:from private static function fromInt (id:Int):GLTransformFeedback {
		
		return GLObject.fromInt (TRANSFORM_FEEDBACK, id);
		
	}
	
	
}


#else
@:native("WebGLTransformFeedback")
extern class GLTransformFeedback {}
#end