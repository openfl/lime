package lime.graphics;


import lime.graphics.cairo.Cairo;


class CairoRenderContext {
	
	
	public var version (get, null):Int;
	public var versionString (get, null):String;
	
	
	public function new () {
		
		
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private inline function get_version ():Int {
		
		return Cairo.version;
		
	}
	
	
	private function get_versionString ():String {
		
		return Cairo.versionString;
		
	}
	
	
}