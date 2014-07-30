package lime.graphics.opengl; #if !js


class GLBuffer extends GLObject {
	
	
	private override function getType ():String {
		
		return "Buffer";
		
	}
	
	
}


#else
typedef GLBuffer = js.html.webgl.Buffer;
#end