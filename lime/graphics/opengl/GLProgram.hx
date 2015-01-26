package lime.graphics.opengl; #if (!js || !html5 || display)


class GLProgram extends GLObject {
	
	
	public var shaders:Array<GLShader>;
	
	
	public function new (version:Int, id:Dynamic) {
		
		super (version, id);
		shaders = new Array<GLShader> ();
		
	}
	
	
	public function attach (shader:GLShader):Void {
		
		shaders.push (shader);
		
	}
	
	
	public function getShaders ():Array<GLShader> {
		
		return shaders.copy ();
		
	}
	
	
	private override function getType ():String {
		
		return "Program";
		
	}
	
	
}


#else
typedef GLProgram = js.html.webgl.Program;
#end