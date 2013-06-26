package lime.gl;

#if lime_native

	class GLFramebuffer extends GLObject {
		
		public function new (version:Int, id:Dynamic) {
			super (version, id);
		}
		
		override function getType ():String {
			return "Framebuffer";
		}
		
	} //GLFramebuffer


#end //lime_native


#if lime_html5
	
	typedef GLFramebuffer = js.html.webgl.Framebuffer;

#end //lime_html5