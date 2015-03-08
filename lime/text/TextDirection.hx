package lime.text;


@:enum abstract TextDirection(Int) to (Int) {
	
	
	var INVALID = 0;
	var LEFT_TO_RIGHT = 4;
	var RIGHT_TO_LEFT = 5;
	var TOP_TO_BOTTOM = 6;
	var BOTTOM_TO_TOP = 7;
	
	
	public var backward (get, never):Bool;
	public var forward (get, never):Bool;
	public var horizontal (get, never):Bool;
	public var vertical (get, never):Bool;
	
	
	public inline function reverse ():Void {
		
		this = this ^ 1;
		
	}
	
	
	public inline function toString ():String {
		
		return switch (this) {
			
			case LEFT_TO_RIGHT: "leftToRight";
			case RIGHT_TO_LEFT: "rightToLeft";
			case TOP_TO_BOTTOM: "topToBottom";
			case BOTTOM_TO_TOP: "bottomToTop";
			default: "";
			
		}
		
	}
	
	
	private inline function get_backward ():Bool {
		
		return (this & ~2) == 5;
		
	}
	
	
	private inline function get_forward ():Bool {
		
		return (this & ~2) == 4;
		
	}
	
	
	private inline function get_horizontal ():Bool {
		
		return (this & ~1) == 4;
		
	}
	
	
	private inline function get_vertical ():Bool {
		
		return (this & ~1) == 6;
		
	}
	
	
}