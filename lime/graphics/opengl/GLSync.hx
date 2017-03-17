package lime.graphics.opengl; #if (!js || !html5 || display)


import lime.graphics.opengl.GL;

@:forward(id)


abstract GLSync(GLObject) from GLObject to GLObject {
	
	
	@:from private static function fromInt (id:Int):GLSync {
		
		return GLObject.fromInt (SYNC, id);
		
	}
	
	
}


#else
@:native("WebGLSync")
extern class GLSync {}
#end