package lime.text;


class GlyphSet {
	
	
	public var glyphs:String;
	public var ranges:Array<GlyphRange>;
	
	
	public function new (glyphs:String = null, rangeStart:Int = -1, rangeEnd:Int = -1) {
		
		ranges = new Array ();
		
		if (glyphs != null) {
			
			addGlyphs (glyphs);
			
		}
		
		if (rangeStart > -1) {
			
			addRange (rangeStart, rangeEnd);
			
		}
		
	}
	
	
	public function addGlyphs (glyphs:String):Void {
		
		this.glyphs += glyphs;
		
	}
	
	
	public function addRange (start:Int = 0, end:Int = -1) {
		
		ranges.push (new GlyphRange (start, end));
		
	}
	
	
}


private class GlyphRange {
	
	
	public var end:Int;
	public var start:Int;
	
	
	public function new (start:Int, end:Int) {
		
		this.start = start;
		this.end = end;
		
	}
	
	
}