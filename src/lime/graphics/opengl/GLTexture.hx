package lime.graphics.opengl; #if (!lime_doc_gen || lime_opengl || lime_opengles || lime_webgl)
#if ((lime_opengl || lime_opengles) && !display)


import lime.graphics.opengl.GL;

@:forward(id)


abstract GLTexture(GLObject) from GLObject to GLObject {
	
	
	@:from private static function fromInt (id:Int):GLTexture {
		
		return GLObject.fromInt (TEXTURE, id);
		
	}
	
	
}


#elseif (lime_webgl && !display)
typedef GLTexture = js.html.webgl.Texture;
#else
typedef GLTexture = Dynamic;
#end
#end