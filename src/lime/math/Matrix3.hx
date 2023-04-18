package lime.math;

/**
	`Matrix3` is a 3x3 transformation matrix particularly useful for
	two-dimensional transformation. It can be used for rotation, scale
	and skewing of a two-dimensional object.

	Although a 3x3 matrix is represented, configurable values can be
	considered as a 3x2 matrix:

	```
	[ a, c, tx ]
	[ c, d, ty ]
	[ 0, 0,  1 ]
	```
**/
#if hl
@:keep
#end
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Matrix3
{
	/**
		The matrix a component, used in scaling and skewing (default is 1)
	**/
	public var a:Float;

	/**
		The matrix b component, used in rotation and skewing (default is 0)
	**/
	public var b:Float;

	/**
		The matrix c component, used in rotation and skewing (default is 0)
	**/
	public var c:Float;

	/**
		The matrix d component, used in scaling and skewing (default is 1)
	**/
	public var d:Float;

	/**
		The matrix tx component, used in translation (default is 0)
	**/
	public var tx:Float;

	/**
		The matrix ty component, used in translation (default is 0)
	**/
	public var ty:Float;

	private static var __identity = new Matrix3();

	/**
		Creates a new `Matrix` instance
		@param	a	(Optional) An initial a component value (default is 1)
		@param	b	(Optional) An initial b component value (default is 0)
		@param	c	(Optional) An initial c component value (default is 0)
		@param	d	(Optional) An initial d component value (default is 1)
		@param	tx	(Optional) An initial tx component value (default is 0)
		@param	ty	(Optional) An initial ty component value (default is 0)
	**/
	public function new(a:Float = 1, b:Float = 0, c:Float = 0, d:Float = 1, tx:Float = 0, ty:Float = 0)
	{
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
		this.tx = tx;
		this.ty = ty;
	}

	/**
		Creates a duplicate of the current `Matrix3`
		@return	A duplicate `Matrix3` instance
	**/
	public inline function clone():Matrix3
	{
		return new Matrix3(a, b, c, d, tx, ty);
	}

	/**
		Concatenates the values of a second matrix to the current
		`Matrix3`, combining the effects of both. This is the same
		as matrix multiplication. The second matrix is not modified.
		@param	m	A second `Matrix3` to concatenate to the current instance
	**/
	public function concat(m:Matrix3):Void
	{
		var a1 = a * m.a + b * m.c;
		b = a * m.b + b * m.d;
		a = a1;

		var c1 = c * m.a + d * m.c;
		d = c * m.b + d * m.d;
		c = c1;

		var tx1 = tx * m.a + ty * m.c + m.tx;
		ty = tx * m.b + ty * m.d + m.ty;
		tx = tx1;
	}

	/**
		Copies the `x` and `y` components from a `Vector4` instance
		to the `a`/`c`, `b`/`d` or the `tx`/`ty` column of the current
		matrix
		@param	column	The column to copy into (0, 1 or 2)
		@param	vector4	The `Vector4` instance to copy from
	**/
	public function copyColumnFrom(column:Int, vector4:Vector4):Void
	{
		if (column > 2)
		{
			throw "Column " + column + " out of bounds (2)";
		}
		else if (column == 0)
		{
			a = vector4.x;
			b = vector4.y;
		}
		else if (column == 1)
		{
			c = vector4.x;
			d = vector4.y;
		}
		else
		{
			tx = vector4.x;
			ty = vector4.y;
		}
	}

	/**
		Copies a column of the current matrix into a `Vector4`
		instance. The `w` value will not be modified.
		@param	column	The column to copy from (0, 1 or 2)
		@param	vector4	The `Vector4` instance to copy to
	**/
	public function copyColumnTo(column:Int, vector4:Vector4):Void
	{
		if (column > 2)
		{
			throw "Column " + column + " out of bounds (2)";
		}
		else if (column == 0)
		{
			vector4.x = a;
			vector4.y = b;
			vector4.z = 0;
		}
		else if (column == 1)
		{
			vector4.x = c;
			vector4.y = d;
			vector4.z = 0;
		}
		else
		{
			vector4.x = tx;
			vector4.y = ty;
			vector4.z = 1;
		}
	}

	/**
		Copies the values of another `Matrix3` and
		applies it to the current instance
		@param	sourceMatrix3	The `Matrix3` to copy from
	**/
	public function copyFrom(sourceMatrix3:Matrix3):Void
	{
		a = sourceMatrix3.a;
		b = sourceMatrix3.b;
		c = sourceMatrix3.c;
		d = sourceMatrix3.d;
		tx = sourceMatrix3.tx;
		ty = sourceMatrix3.ty;
	}

	/**
		Copies the values of a `Vector4` instance into a row
		of the current matrix
		@param	row	The row to copy into (0 or 1)
		@param	vector4	The `Vector4` instance to copy from
	**/
	public function copyRowFrom(row:Int, vector4:Vector4):Void
	{
		if (row > 2)
		{
			throw "Row " + row + " out of bounds (2)";
		}
		else if (row == 0)
		{
			a = vector4.x;
			c = vector4.y;
			tx = vector4.z;
		}
		else if (row == 1)
		{
			b = vector4.x;
			d = vector4.y;
			ty = vector4.z;
		}
	}

	/**
		Copies a row of the current matrix into a `Vector4`
		instance. The `w` value will not be modified.
		@param	row	The row to copy into (0, 1 or 2)
		@param	vector4	The `Vector4` instance to copy from
	**/
	public function copyRowTo(row:Int, vector4:Vector4):Void
	{
		if (row > 2)
		{
			throw "Row " + row + " out of bounds (2)";
		}
		else if (row == 0)
		{
			vector4.x = a;
			vector4.y = c;
			vector4.z = tx;
		}
		else if (row == 1)
		{
			vector4.x = b;
			vector4.y = d;
			vector4.z = ty;
		}
		else
		{
			vector4.setTo(0, 0, 1);
		}
	}

	/**
		Applies a two-dimensional transformation to the current matrix.

		This is the same as calling `identity()`, `rotate()`, `scale()`
		then `translate()` with these values.
		@param	scaleX	An x scale transformation value
		@param	scaleY	A y scale transformation value
		@param	rotation (Optional) A rotation value (default is 0)
		@param	tx	(Optional) A translate x value (default is 0)
		@param	ty	(Optional) A translate y value (default is 0)
	**/
	public function createBox(scaleX:Float, scaleY:Float, rotation:Float = 0, tx:Float = 0, ty:Float = 0):Void
	{
		if (rotation != 0)
		{
			var cos = Math.cos(rotation);
			var sin = Math.sin(rotation);

			a = cos * scaleX;
			b = sin * scaleY;
			c = -sin * scaleX;
			d = cos * scaleY;
		}
		else
		{
			a = scaleX;
			b = 0;
			c = 0;
			d = scaleY;
		}

		this.tx = tx;
		this.ty = ty;
	}

	/**
		Creates a matrix to use for a linear gradient fill
		@param	width	The width of the gradient fill
		@param	height	The height of the gradient fill
		@param	rotation	(Optional) A rotation for the gradient fill (default is 0)
		@param	tx	(Optional) An x offset for the gradient fill (default is 0)
		@param	ty	(Optional) A y offset for the gradient fill (default is 0)
		@return	A new `Matrix` instance
	**/
	public function createGradientBox(width:Float, height:Float, rotation:Float = 0, tx:Float = 0, ty:Float = 0):Void
	{
		a = width / 1638.4;
		d = height / 1638.4;

		// rotation is clockwise
		if (rotation != 0)
		{
			var cos = Math.cos(rotation);
			var sin = Math.sin(rotation);

			b = sin * d;
			c = -sin * a;
			a *= cos;
			d *= cos;
		}
		else
		{
			b = 0;
			c = 0;
		}

		this.tx = tx + width / 2;
		this.ty = ty + height / 2;
	}

	/**
		Check if two matrices have the same values
		@return	Whether both matrices are equal
	**/
	public function equals(matrix3:Matrix3):Bool
	{
		return (matrix3 != null && tx == matrix3.tx && ty == matrix3.ty && a == matrix3.a && b == matrix3.b && c == matrix3.c && d == matrix3.d);
	}

	/**
		Transforms a `Vector2` instance by the current matrix,
		without considering the `tx` and `ty` values of the matrix
		@param	result	(Optional) An existing `Vector2` instance to fill with the result
		@return	A new `Vector2` instance representing the transformed values
	**/
	public function deltaTransformVector(Vector2:Vector2, result:Vector2 = null):Vector2
	{
		if (result == null) result = new Vector2();
		result.x = Vector2.x * a + Vector2.y * c;
		result.y = Vector2.x * b + Vector2.y * d;
		return result;
	}

	/**
		Resets the matrix to default identity values
	**/
	public function identity():Void
	{
		a = 1;
		b = 0;
		c = 0;
		d = 1;
		tx = 0;
		ty = 0;
	}

	/**
		Inverts the values of the current matrix
		@return	The current matrix instance
	**/
	public function invert():Matrix3
	{
		var norm = a * d - b * c;

		if (norm == 0)
		{
			a = b = c = d = 0;
			tx = -tx;
			ty = -ty;
		}
		else
		{
			norm = 1.0 / norm;
			var a1 = d * norm;
			d = a * norm;
			a = a1;
			b *= -norm;
			c *= -norm;

			var tx1 = -a * tx - c * ty;
			ty = -b * tx - d * ty;
			tx = tx1;
		}

		return this;
	}

	// public inline function mult (m:Matrix3) {
	// 	var result = clone ();
	// 	result.concat (m);
	// 	return result;
	// }

	/**
		Applies rotation to the current matrix
		@param	theta	A rotation value in degrees
	**/
	public function rotate(theta:Float):Void
	{
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

		var cos = Math.cos(theta);
		var sin = Math.sin(theta);

		var a1 = a * cos - b * sin;
		b = a * sin + b * cos;
		a = a1;

		var c1 = c * cos - d * sin;
		d = c * sin + d * cos;
		c = c1;

		var tx1 = tx * cos - ty * sin;
		ty = tx * sin + ty * cos;
		tx = tx1;
	}

	/**
		Scales the current matrix
		@param	sx	The x scale to apply
		@param	sy	The y scale to apply
	**/
	public function scale(sx:Float, sy:Float):Void
	{
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
	}

	@:noCompletion private inline function setRotation(theta:Float, scale:Float = 1):Void
	{
		a = Math.cos(theta) * scale;
		c = Math.sin(theta) * scale;
		b = -c;
		d = a;
	}

	/**
		Sets the values of the current matrix
		@param	a	The new matrix a value
		@param	b	The new matrix b value
		@param	c	The new matrix c value
		@param	d	The new matrix d value
		@param	tx	The new matrix tx value
		@param	ty	The new matrix ty value
	**/
	public #if !js inline #end function setTo(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Void
	{
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
		this.tx = tx;
		this.ty = ty;
	}

	@:dox(hide) @:noCompletion public inline function to3DString(roundPixels:Bool = false):String
	{
		// identity matrix
		//  [a,b,tx,0],
		//  [c,d,ty,0],
		//  [0,0,1, 0],
		//  [0,0,0, 1]
		//
		// matrix3d(a,       b, 0, 0, c, d,       0, 0, 0, 0, 1, 0, tx,     ty, 0, 1)

		if (roundPixels)
		{
			return "matrix3d("
				+ a
				+ ", "
				+ b
				+ ", "
				+ "0, 0, "
				+ c
				+ ", "
				+ d
				+ ", "
				+ "0, 0, 0, 0, 1, 0, "
				+ Std.int(tx)
				+ ", "
				+ Std.int(ty)
				+ ", 0, 1)";
		}
		else
		{
			return "matrix3d(" + a + ", " + b + ", " + "0, 0, " + c + ", " + d + ", " + "0, 0, 0, 0, 1, 0, " + tx + ", " + ty + ", 0, 1)";
		}
	}

	@:dox(hide) public inline function toString():String
	{
		return "matrix(" + a + ", " + b + ", " + c + ", " + d + ", " + tx + ", " + ty + ")";
	}

	/**
		Transforms a `Rectangle` instance by the current matrix
		and returns `Rectangle` with the bounds of the transformed
		rectangle.
		@param	transform	A `Matrix3` instance to transform by
		@param	result	(Optional) A `Rectangle` instance to use for the result
		@return	A `Rectangle` represented the transformed bounds
	**/
	public function transformRect(rect:Rectangle, result:Rectangle = null):Rectangle
	{
		if (result == null) result = new Rectangle();

		var tx0 = a * rect.x + c * rect.y;
		var tx1 = tx0;
		var ty0 = b * rect.x + d * rect.y;
		var ty1 = ty0;

		var tx = a * (rect.x + rect.width) + c * rect.y;
		var ty = b * (rect.x + rect.width) + d * rect.y;

		if (tx < tx0) tx0 = tx;
		if (ty < ty0) ty0 = ty;
		if (tx > tx1) tx1 = tx;
		if (ty > ty1) ty1 = ty;

		tx = a * (rect.x + rect.width) + c * (rect.y + rect.height);
		ty = b * (rect.x + rect.width) + d * (rect.y + rect.height);

		if (tx < tx0) tx0 = tx;
		if (ty < ty0) ty0 = ty;
		if (tx > tx1) tx1 = tx;
		if (ty > ty1) ty1 = ty;

		tx = a * rect.x + c * (rect.y + rect.height);
		ty = b * rect.x + d * (rect.y + rect.height);

		if (tx < tx0) tx0 = tx;
		if (ty < ty0) ty0 = ty;
		if (tx > tx1) tx1 = tx;
		if (ty > ty1) ty1 = ty;

		result.setTo(tx0 + tx, ty0 + ty, tx1 - tx0, ty1 - ty0);
		return result;
	}

	/**
		Transforms a `Vector2` instance by the current matrix
		@param	result	(Optional) An existing `Vector2` instance to fill with the result
		@return	A new `Vector2` instance representing the transformed values
	**/
	public function transformVector(pos:Vector2, result:Vector2 = null):Vector2
	{
		if (result == null) result = new Vector2();
		result.x = pos.x * a + pos.y * c + tx;
		result.y = pos.x * b + pos.y * d + ty;
		return result;
	}

	/**
		Adjusts the `tx` and `ty` of the current matrix
		@param	dx	The x amount to translate
		@param	dy	The y amount to translate
	**/
	public inline function translate(dx:Float, dy:Float)
	{
		tx += dx;
		ty += dy;
	}
}
