package lime.gl;


#if lime_native

	class GLShader extends GLObject {
		
		public function new (version:Int, id:Dynamic) {
			super (version, id);
		}
		
		override private function getType ():String {
			return "Shader";
		}
		
	}

#end //lime_native

#if lime_html5
	
	typedef GLShader = js.html.webgl.Shader;

#end //lime_html5