package lime.text;


import lime.math.Vector2;


class GlyphPosition {
	
	
	public var advance:Vector2;
	public var glyph:Glyph;
	public var offset:Vector2;
	
	
	public function new (glyph:Glyph, advance:Vector2, offset:Vector2 = null) {
		
		this.glyph = glyph;
		this.advance = advance;
		
		if (offset != null) {
			
			this.offset = offset;
			
		} else {
			
			this.offset = new Vector2 ();
			
		}
		
	}
	
}