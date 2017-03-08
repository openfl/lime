package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLQuery {
	
	
	private var id:Int;
	
	
	private function new (id:Int) {
		
		this.id = id;
		
	}
	
	
}


#else


@:native("WebGLQuery")
extern class GLQuery {
	
	
	
	
	
}


#end