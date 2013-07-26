package lime.gl;

#if lime_html5

	typedef GLBuffer = js.html.webgl.Buffer;
	
#else

	class GLBuffer extends GLObject {
		public function new (version:Int, id:Dynamic) {
			super (version, id);
		}
		override function getType ():String {
			return "Buffer";
		}
	}

#end //lime_html5