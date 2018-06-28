package lime.math;


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class Matrix3 {
	
	
	public var a:Float;
	public var b:Float;
	public var c:Float;
	public var d:Float;
	public var tx:Float;
	public var ty:Float;
	
	private static var __identity = new Matrix3 ();
	
	
	public function new (a:Float = 1, b:Float = 0, c:Float = 0, d:Float = 1, tx:Float = 0, ty:Float = 0) {
		
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
		this.tx = tx;
		this.ty = ty;
		
	}
	
	
	public inline function clone ():Matrix3 {
		
		return new Matrix3 (a, b, c, d, tx, ty);
		
	}
	
	
	public function concat (m:Matrix3):Void {
		
		var a1 = a * m.a + b * m.c;
		b = a * m.b + b * m.d;
		a = a1;

		var c1 = c * m.a + d * m.c;
		d = c * m.b + d * m.d;
		c = c1;
		
		var tx1 = tx * m.a + ty * m.c + m.tx;
		ty = tx * m.b + ty * m.d + m.ty;
		tx = tx1;
		
		//__cleanValues ();
		
	}
	
	
	public function copyColumnFrom (column:Int, vector4:Vector4):Void {
		
		if (column > 2) {
			
			throw "Column " + column + " out of bounds (2)";
			
		} else if (column == 0) {
			
			a = vector4.x;
			c = vector4.y;
			
		}else if (column == 1) {
			
			b = vector4.x;
			d = vector4.y;
			
		}else {
			
			tx = vector4.x;
			ty = vector4.y;
			
		}
		
	}
	
	
	public function copyColumnTo (column:Int, vector4:Vector4):Void {
		
		if (column > 2) {
			
			throw "Column " + column + " out of bounds (2)";
			
		} else if (column == 0) {
			
			vector4.x = a;
			vector4.y = c;
			vector4.z = 0;
			
		} else if (column == 1) {
			
			vector4.x = b;
			vector4.y = d;
			vector4.z = 0;
			
		} else {
			
			vector4.x = tx;
			vector4.y = ty;
			vector4.z = 1;
			
		}
		
	}
	
	
	public function copyFrom (sourceMatrix3:Matrix3):Void {
		
		a = sourceMatrix3.a;
		b = sourceMatrix3.b;
		c = sourceMatrix3.c;
		d = sourceMatrix3.d;
		tx = sourceMatrix3.tx;
		ty = sourceMatrix3.ty;
		
	}
	
	
	public function copyRowFrom (row:Int, vector4:Vector4):Void {
		
		if (row > 2) {
			
			throw "Row " + row + " out of bounds (2)";
			
		} else if (row == 0) {
			
			a = vector4.x;
			c = vector4.y;
			
		} else if (row == 1) {
			
			b = vector4.x;
			d = vector4.y;
			
		} else {
			
			tx = vector4.x;
			ty = vector4.y;
			
		}
		
	}
	
	
	public function copyRowTo (row:Int, vector4:Vector4):Void {
		
		if (row > 2) {
			
			throw "Row " + row + " out of bounds (2)";
			
		} else if (row == 0) {
			
			vector4.x = a;
			vector4.y = b;
			vector4.z = tx;
			
		} else if (row == 1) {
			
			vector4.x = c;
			vector4.y = d;
			vector4.z = ty;
			
		}else {
			
			vector4.setTo (0, 0, 1);
			
		}
		
	}
	
	
	public function createBox (scaleX:Float, scaleY:Float, rotation:Float = 0, tx:Float = 0, ty:Float = 0):Void {
		
		a = scaleX;
		d = scaleY;
		b = rotation;
		this.tx = tx;
		this.ty = ty;
		
	}
	
	
	public function createGradientBox (width:Float, height:Float, rotation:Float = 0, tx:Float = 0, ty:Float = 0):Void {
		
		a = width / 1638.4;
		d = height / 1638.4;
		
		// rotation is clockwise
		if (rotation != 0) {
			
			var cos = Math.cos (rotation);
			var sin = Math.sin (rotation);
			
			b = sin * d;
			c = -sin * a;
			a *= cos;
			d *= cos;
			
		} else {
			
			b = 0;
			c = 0;
			
		}
		
		this.tx = tx + width / 2;
		this.ty = ty + height / 2;
		
	}
	
	
	public function equals (Matrix3):Bool {
		
		return (Matrix3 != null && tx == Matrix3.tx && ty == Matrix3.ty && a == Matrix3.a && b == Matrix3.b && c == Matrix3.c && d == Matrix3.d);
		
	}
	
	
	public function deltaTransformVector2 (Vector2:Vector2):Vector2 {
		
		return new Vector2 (Vector2.x * a + Vector2.y * c, Vector2.x * b + Vector2.y * d);
		
	}
	
	
	public function identity ():Void {
		
		a = 1;
		b = 0;
		c = 0;
		d = 1;
		tx = 0;
		ty = 0;
		
	}
	
	
	public function invert ():Matrix3 {
		
		var norm = a * d - b * c;
		
		if (norm == 0) {
			
			a = b = c = d = 0;
			tx = -tx;
			ty = -ty;
			
		} else {
			
			norm = 1.0 / norm;
			var a1 = d * norm;
			d = a * norm;
			a = a1;
			b *= -norm;
			c *= -norm;
			
			var tx1 = - a * tx - c * ty;
			ty = - b * tx - d * ty;
			tx = tx1;
			
		}
		
		//__cleanValues ();
		
		return this;
		
	}
	
	
	public inline function mult (m:Matrix3) {
		
		var result = clone ();
		result.concat (m);
		return result;
		
	}
	
	
	public function rotate (theta:Float):Void {
		
		/*
		   Rotate object "after" other transforms
			
		   [  a  b   0 ][  ma mb  0 ]
		   [  c  d   0 ][  mc md  0 ]
		   [  tx ty  1 ][  mtx mty 1 ]
			
		   ma = md = cos
		   mb = sin
		   mc = -sin
		   mtx = my = 0
			
		 */
		
		var cos = Math.cos (theta);
		var sin = Math.sin (theta);
		
		var a1 = a * cos - b * sin;
		b = a * sin + b * cos;
		a = a1;
		
		var c1 = c * cos - d * sin;
		d = c * sin + d * cos;
		c = c1;
		
		var tx1 = tx * cos - ty * sin;
		ty = tx * sin + ty * cos;
		tx = tx1;
		
		//__cleanValues ();
		
	}
	
	
	public function scale (sx:Float, sy:Float) {
		
		/*
			
		   Scale object "after" other transforms
			
		   [  a  b   0 ][  sx  0   0 ]
		   [  c  d   0 ][  0   sy  0 ]
		   [  tx ty  1 ][  0   0   1 ]
		 */
		
		a *= sx;
		b *= sy;
		c *= sx;
		d *= sy;
		tx *= sx;
		ty *= sy;
		
		//__cleanValues ();
		
	}
	
	
	private inline function setRotation (theta:Float, scale:Float = 1) {
		
		a = Math.cos (theta) * scale;
		c = Math.sin (theta) * scale;
		b = -c;
		d = a;
		
		//__cleanValues ();
		
	}
	
	
	public function setTo (a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Void {
		
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
		this.tx = tx;
		this.ty = ty;
		
	}
	
	
	public inline function to3DString (roundPixels:Bool = false):String {
		
		// identityMatrix3
		//  [a,b,tx,0],
		//  [c,d,ty,0],
		//  [0,0,1, 0],
		//  [0,0,0, 1]
		//
		// Matrix33d(a,       b, 0, 0, c, d,       0, 0, 0, 0, 1, 0, tx,     ty, 0, 1)
		
		if (roundPixels) {
			
			return "Matrix33d(" + a + ", " + b + ", " + "0, 0, " + c + ", " + d + ", " + "0, 0, 0, 0, 1, 0, " + Std.int (tx) + ", " + Std.int (ty) + ", 0, 1)";
			
		} else {
			
			return "Matrix33d(" + a + ", " + b + ", " + "0, 0, " + c + ", " + d + ", " + "0, 0, 0, 0, 1, 0, " + tx + ", " + ty + ", 0, 1)";
			
		}
		
	}
	
	
	public inline function toMozString () {
		
		return "Matrix3(" + a + ", " + b + ", " + c + ", " + d + ", " + tx + "px, " + ty + "px)";
		
	}
	
	
	public inline function toString ():String {
		
		return "Matrix3(" + a + ", " + b + ", " + c + ", " + d + ", " + tx + ", " + ty + ")";
		
	}
	
	
	public function transformVector2 (pos:Vector2) {
		
		return new Vector2 (__transformX (pos), __transformY (pos));
		
	}
	
	
	public inline function translate (dx:Float, dy:Float) {
		
		tx += dx;
		ty += dy;
		
	}
	
	
	private inline function __cleanValues ():Void {
		
		a = Math.round (a * 1000) / 1000;
		b = Math.round (b * 1000) / 1000;
		c = Math.round (c * 1000) / 1000;
		d = Math.round (d * 1000) / 1000;
		tx = Math.round (tx * 10) / 10;
		ty = Math.round (ty * 10) / 10;
		
	}
	
	
	public inline function __transformX (pos:Vector2):Float {
		
		return pos.x * a + pos.y * c + tx;
		
	}
	
	
	public inline function __transformY (pos:Vector2):Float {
		
		return pos.x * b + pos.y * d + ty;
		
	}
	
	
	public inline function __translateTransformed (pos:Vector2):Void {
		
		tx = __transformX (pos);
		ty = __transformY (pos);
		
		//__cleanValues ();
		
	}
	
	
}
