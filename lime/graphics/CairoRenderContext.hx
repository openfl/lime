package lime.graphics; #if (cpp || neko || nodejs)


import lime.system.System;


class CairoRenderContext {
	
	
	public var version (get, null):Int;
	public var versionString (get, null):String;
	
	
	public function new () {
		
		
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_version ():Int {
		
		return lime_cairo_version ();
		
	}
	
	
	private function get_versionString ():String {
		
		return lime_cairo_version_string ();
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private var lime_cairo_version = System.load ("lime", "lime_cairo_version", 0);
	private var lime_cairo_version_string = System.load ("lime", "lime_cairo_version_string", 0);
	
	
}


#else


class CairoRenderContext {
	
	
	public function new () {
		
		
		
	}
	
	
	public function version ():Int { return 0 };
	public function versionString ():String { return "" };
	
	
}


#end