package lime.text;


import lime.graphics.Image;


class Glyph {
	
	
	public var charCode:Int;
	public var image:Image;
	public var index:Int;
	public var metrics:GlyphMetrics;
	public var x:Int;
	public var y:Int;
	
	
	public function new (charCode:Int = -1, index:Int = -1) {
		
		this.charCode = charCode;
		this.index = index;
		
	}
	
	
}