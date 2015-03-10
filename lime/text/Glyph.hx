package lime.text;


import lime.graphics.Image;


class Glyph {
	
	
	public var charCode:Int;
	public var glyphIndex:Int;
	public var image:Image;
	public var metrics:GlyphMetrics;
	public var x:Int;
	public var y:Int;
	
	
	public function new (charCode:Int = 0, glyphIndex:Int = 0) {
		
		this.charCode = charCode;
		this.glyphIndex = glyphIndex;
		
	}
	
	
}