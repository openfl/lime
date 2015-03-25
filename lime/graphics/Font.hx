package lime.graphics;


#if (openfl < "3.0.0")


class Font extends lime.text.Font {
	
	
	public var fontName (get, set):String;
	
	
	public function new (fontName:String = null) {
		
		super (fontName);
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_fontName ():String {
		
		return name;
		
	}
	
	
	private function set_fontName (value:String):String {
		
		return name = value;
		
	}
	
	
	
}


#end