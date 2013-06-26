package lime.gl;


#if lime_native

	class GLTexture extends GLObject {
		
		public function new (version:Int, id:Dynamic) {
			super (version, id);
		}
		
		override private function getType ():String {
			return "Texture";
		}
		
	}

#end //lime_native


#if lime_html5

	typedef GLTexture = js.html.webgl.Texture;

#end //lime_html5