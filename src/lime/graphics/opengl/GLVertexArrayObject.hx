package lime.graphics.opengl; #if lime_opengl #if (!js || !html5 || display)


import lime.graphics.opengl.GL;

@:forward(id)


abstract GLVertexArrayObject(GLObject) from GLObject to GLObject {
	
	
	@:from private static function fromInt (id:Int):GLVertexArrayObject {
		
		return GLObject.fromInt (VERTEX_ARRAY_OBJECT, id);
		
	}
	
	
}


#else
@:native("WebGLVertexArrayObject")
extern class GLVertexArrayObject {}
#end
#else
typedef GLVertexArrayObject = Dynamic;
#end