package lime.graphics.opengl; #if (!js || !html5 || display)


import lime.graphics.opengl.GL;

@:forward(id)


abstract GLTexture(GLObject) from GLObject to GLObject {
	
	
	@:from private static function fromInt (id:Int):GLTexture {
		
		return GLObject.fromInt (TEXTURE, id);
		
	}
	
	
}


#else
typedef GLTexture = js.html.webgl.Texture;
#end