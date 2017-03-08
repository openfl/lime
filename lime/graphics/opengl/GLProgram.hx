package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLProgram {
	
	
	private var id:Int;
	private var shaders:Array<GLShader>;
	
	
	private function new (id:Int) {
		
		this.id = id;
		shaders = [];
		
	}
	
	
}


#else
typedef GLProgram = js.html.webgl.Program;
#end