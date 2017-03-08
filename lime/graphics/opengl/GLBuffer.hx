package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLBuffer {
	
	
	private var id:Int;
	
	
	private function new (id:Int) {
		
		this.id = id;
		
	}
	
	
}


#else
typedef GLBuffer = js.html.webgl.Buffer;
#end