package lime.math;


#if flash
import flash.geom.Point;
#end

#if hl @:keep #end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class Vector2 {
	
	
	public var length (get, null):Float;
	public var x:Float;
	public var y:Float;
	
	
	public function new (x:Float = 0, y:Float = 0) {
		
		this.x = x;
		this.y = y;
		
	}
	
	
	public function add (v:Vector2):Vector2 {
		
		return new Vector2 (v.x + x, v.y + y);
		
	}
	
	
	public function clone ():Vector2 {
		
		return new Vector2 (x, y);
		
	}
	
	
	public static function distance (pt1:Vector2, pt2:Vector2):Float {
		
		var dx = pt1.x - pt2.x;
		var dy = pt1.y - pt2.y;
		return Math.sqrt (dx * dx + dy * dy);
		
	}
	
	
	public function equals (toCompare:Vector2):Bool {
		
		return toCompare != null && toCompare.x == x && toCompare.y == y;
		
	}
	
	
	public static function interpolate (pt1:Vector2, pt2:Vector2, f:Float):Vector2 {
		
		return new Vector2 (pt2.x + f * (pt1.x - pt2.x), pt2.y + f * (pt1.y - pt2.y));
		
	}
	
	
	public function normalize (thickness:Float):Void {
		
		if (x == 0 && y == 0) {
			
			return;
			
		} else {
			
			var norm = thickness / Math.sqrt (x * x + y * y);
			x *= norm;
			y *= norm;
			
		}
		
	}
	
	
	public function offset (dx:Float, dy:Float):Void {
		
		x += dx;
		y += dy;
		
	}
	
	
	public static function polar (len:Float, angle:Float):Vector2 {
		
		return new Vector2 (len * Math.cos (angle), len * Math.sin (angle));
		
	}
	
	
	inline public function setTo (xa:Float, ya:Float):Void {	
		
		x = xa;
		y = ya;
	}
	
	
	public function subtract (v:Vector2):Vector2 {
		
		return new Vector2 (x - v.x, y - v.y);
		
	}
	
	
	private function __toFlashPoint ():#if flash Point #else Dynamic #end {
		
		#if flash
		return new Point (x, y);
		#else
		return null;
		#end
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_length ():Float {
		
		return Math.sqrt (x * x + y * y);
		
	}
	
	
}