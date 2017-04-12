package lime.graphics.opengl; #if lime_opengl #if (!js || !html5 || display)


import lime.graphics.opengl.GL;

@:forward(id)


abstract GLFramebuffer(GLObject) from GLObject to GLObject {
	
	
	@:from private static function fromInt (id:Int):GLFramebuffer {
		
		return GLObject.fromInt (FRAMEBUFFER, id);
		
	}
	
	
}


#else
typedef GLFramebuffer = js.html.webgl.Framebuffer;
#end
#else
typedef GLFramebuffer = Dynamic;
#end