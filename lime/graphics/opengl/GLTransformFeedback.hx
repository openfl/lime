package lime.graphics.opengl; #if lime_opengl #if (!js || !html5 || display)


import lime.graphics.opengl.GL;

@:forward(id)


abstract GLTransformFeedback(GLObject) from GLObject to GLObject {
	
	
	@:from private static function fromInt (id:Int):GLTransformFeedback {
		
		return GLObject.fromInt (TRANSFORM_FEEDBACK, id);
		
	}
	
	
}


#else
@:native("WebGLTransformFeedback")
extern class GLTransformFeedback {}
#end
#else
typedef GLTransformFeedback = Dynamic;
#end