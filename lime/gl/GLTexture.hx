package lime.gl;


#if lime_html5

	typedef GLTexture = js.html.webgl.Texture;

#else //lime_html5

	class GLTexture extends GLObject {
		
		public function new (version:Int, id:Dynamic) {
			super (version, id);
		}
		
		override private function getType ():String {
			return "Texture";
		}
		
	}

#end //lime_native


