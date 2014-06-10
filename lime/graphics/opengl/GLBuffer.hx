package lime.graphics.opengl;
#if js
typedef GLBuffer = js.html.webgl.Buffer;
#else


class GLBuffer extends GLObject {
	
	
	private override function getType ():String {
		
		return "Buffer";
		
	}
	
	
}


#end