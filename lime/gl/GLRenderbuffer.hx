package lime.gl;


#if lime_native

	class GLRenderbuffer extends GLObject {
		
		public function new (version:Int, id:Dynamic) {
			super (version, id);
		}
		
		override private function getType ():String {
			return "Renderbuffer";
		}
		
	}

#end //lime_native

#if lime_html5

	typedef GLRenderbuffer = js.html.webgl.Renderbuffer;

#end //lime_html5