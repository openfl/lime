package lime.graphics.opengl; #if lime_opengl #if (!js || !html5 || display)


import lime.graphics.opengl.GL;

@:forward(id)


abstract GLBuffer(GLObject) from GLObject to GLObject {
	
	
	@:from private static function fromInt (id:Int):GLBuffer {
		
		return GLObject.fromInt (BUFFER, id);
		
	}
	
	
}


#else
typedef GLBuffer = js.html.webgl.Buffer;
#end
#else
typedef GLBuffer = Dynamic;
#end