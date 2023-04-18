package lime.math;

/**
	`Vector4` is a vector suitable for three-dimensional
	math, containing (x, y, z, w) components
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Vector4
{
	/**
		A constant representing the x axis (1, 0, 0)
	**/
	public static var X_AXIS(get, never):Vector4;

	/**
		A constant representing the y axis (0, 1, 0)
	**/
	public static var Y_AXIS(get, never):Vector4;

	/**
		A constant representing the z axis (0, 0, 1)
	**/
	public static var Z_AXIS(get, never):Vector4;

	/**
		Get the length of this vector
	**/
	public var length(get, never):Float;

	/**
		Get the squared length of this vector
		(avoiding the use of `Math.sqrt` for faster
		performance)
	**/
	public var lengthSquared(get, never):Float;

	/**
		The w component value
	**/
	public var w:Float;

	/**
		The x component value
	**/
	public var x:Float;

	/**
		The y component value
	**/
	public var y:Float;

	/**
		The z component value
	**/
	public var z:Float;

	/**
		Creates a new `Vector4` instance
		@param	x	(Optional) An initial x value (default is 0)
		@param	y	(Optional) An initial y value (default is 0)
		@param	z	(Optional) An initial z value (default is 0)
		@param	w	(Optional) An initial w value (default is 0)
	**/
	public function new(x:Float = 0., y:Float = 0., z:Float = 0., w:Float = 0.)
	{
		this.w = w;
		this.x = x;
		this.y = y;
		this.z = z;
	}

	/**
		Adds two `Vector4` instances together and returns the result
		@param	a	A `Vector4` instance to add to the current one
		@param	result	(Optional) A `Vector4` instance to store the result
		@return	A `Vector4` instance with the added value
	**/
	public inline function add(a:Vector4, result:Vector4 = null):Vector4
	{
		if (result == null) result = new Vector4();
		result.setTo(this.x + a.x, this.y + a.y, this.z + a.z);
		return result;
	}

	/**
		Calculates the angle between two `Vector4` coordinates
		@param	a	A `Vector4` instance
		@param	b	A second `Vector4` instance
		@return	The calculated angle
	**/
	public static inline function angleBetween(a:Vector4, b:Vector4):Float
	{
		var a0 = a.clone();
		a0.normalize();
		var b0 = b.clone();
		b0.normalize();

		return Math.acos(a0.dotProduct(b0));
	}

	/**
		Creates a new `Vector4` instance with the same values as the current one
		@return	A new `Vector4` instance with the same values
	**/
	public inline function clone():Vector4
	{
		return new Vector4(x, y, z, w);
	}

	/**
		Copies the x, y and z component values of another `Vector4` instance
		@param	sourceVector4	A `Vector4` instance to copy from
	**/
	public inline function copyFrom(sourceVector4:Vector4):Void
	{
		x = sourceVector4.x;
		y = sourceVector4.y;
		z = sourceVector4.z;
	}

	/**
		Performs vector multiplication between this vector and another `Vector4` instance
		@param	a	A `Vector4` instance to multiply by
		@param	result	(Optional) A `Vector4` to use for the result
		@return	A `Vector4` instance with the result
	**/
	public inline function crossProduct(a:Vector4, result:Vector4 = null):Vector4
	{
		if (result == null) result = new Vector4();
		result.setTo(y * a.z - z * a.y, z * a.x - x * a.z, x * a.y - y * a.x);
		result.w = 1;
		return result;
	}

	/**
		Decrements the x, y and z component values by those in another `Vector4` instance
		@param	a	A `Vector4` instance to decrement the current vector by
	**/
	public inline function decrementBy(a:Vector4):Void
	{
		x -= a.x;
		y -= a.y;
		z -= a.z;
	}

	/**
		Calculates the distance between two vectors
		@param	pt1	A `Vector4` instance
		@param	pt2	A second `Vector4` instance
		@return	The distance between each vector
	**/
	public inline static function distance(pt1:Vector4, pt2:Vector4):Float
	{
		var x = pt2.x - pt1.x;
		var y = pt2.y - pt1.y;
		var z = pt2.z - pt1.z;

		return Math.sqrt(x * x + y * y + z * z);
	}

	/**
		Calculates the squared distance between two vectors,
		(avoids the use of `Math.sqrt` for faster performance)
		@param	pt1	A `Vector4` instance
		@param	pt2	A second `Vector4` instance
		@return	The square of the distance between each vector
	**/
	public inline static function distanceSquared(pt1:Vector4, pt2:Vector4):Float
	{
		var x = pt2.x - pt1.x;
		var y = pt2.y - pt1.y;
		var z = pt2.z - pt1.z;

		return x * x + y * y + z * z;
	}

	/**
		Calculates the dot product of the current vector with another `Vector4` instance
		@param	a	A `Vector4` instance to use in the dot product
		@return	The calculated dot product value
	**/
	public inline function dotProduct(a:Vector4):Float
	{
		return x * a.x + y * a.y + z * a.z;
	}

	/**
		Whether two `Vector4` instances have equal component values.

		Comparing the w component value is optional.
		@param	toCompare	A `Vector4` instance to compare against
		@param	allFour	(Optional) Whether to compare against the w component (default is false)
		@return	Whether both instances have equal values
	**/
	public inline function equals(toCompare:Vector4, ?allFour:Bool = false):Bool
	{
		return x == toCompare.x && y == toCompare.y && z == toCompare.z && (!allFour || w == toCompare.w);
	}

	/**
		Increments the x, y and z component values by those in a second `Vector4` instance
		@param	a	A `Vector4` instance to increment the current vector by
	**/
	public inline function incrementBy(a:Vector4):Void
	{
		x += a.x;
		y += a.y;
		z += a.z;
	}

	/**
		Whether two `Vector4` instances have nearly equal component values.
		Comparison is performed within a given tolerance value.
		@param	toCompare	A `Vector4` instance to compare against
		@param	tolerance	A floating point value determining how near the values must be to be considered near equal
		@param	allFour	(Optional) Whether to compare against the w component (default is false)
		@return	Whether both instances have equal values, within the given tolerance
	**/
	public inline function nearEquals(toCompare:Vector4, tolerance:Float, ?allFour:Bool = false):Bool
	{
		return Math.abs(x - toCompare.x) < tolerance
			&& Math.abs(y - toCompare.y) < tolerance
			&& Math.abs(z - toCompare.z) < tolerance
			&& (!allFour || Math.abs(w - toCompare.w) < tolerance);
	}

	/**
		Negates the x, y and z values of the current vector
		(multiplying each value by -1)
	**/
	public inline function negate():Void
	{
		x *= -1;
		y *= -1;
		z *= -1;
	}

	/**
		Divides the x, y and z component values by the
		length of the vector
	**/
	public inline function normalize():Float
	{
		var l = length;

		if (l != 0)
		{
			x /= l;
			y /= l;
			z /= l;
		}

		return l;
	}

	/**
		Divides the x, y and z component values by the
		w component value
	**/
	public inline function project():Void
	{
		x /= w;
		y /= w;
		z /= w;
	}

	/**
		Scales the x, y and z component values by a scale value
		@param	s	The amount of scale to apply
	**/
	public inline function scaleBy(s:Float):Void
	{
		x *= s;
		y *= s;
		z *= s;
	}

	/**
		Sets the x, y and z component values
		@param	xa	An x value
		@param	ya	A y value
		@param	za	A z value
	**/
	public inline function setTo(xa:Float, ya:Float, za:Float):Void
	{
		x = xa;
		y = ya;
		z = za;
	}

	/**
		Subtracts the values of a second `Vector4` instance
		from the current one
		@param	a	A second `Vector4` instance to substract
		@param	result	(Optional) A `Vector4` instance to store the result
		@return	A `Vector4` instance containing the subtracted value
	**/
	public inline function subtract(a:Vector4, result:Vector4 = null):Vector4
	{
		if (result == null) result = new Vector4();
		result.setTo(x - a.x, y - a.y, z - a.z);
		return result;
	}

	@:dox(hide) public inline function toString():String
	{
		return "Vector4(" + x + ", " + y + ", " + z + ")";
	}

	// Getters & Setters
	@:noCompletion private inline function get_length():Float
	{
		return Math.sqrt(x * x + y * y + z * z);
	}

	@:noCompletion private inline function get_lengthSquared():Float
	{
		return x * x + y * y + z * z;
	}

	private inline static function get_X_AXIS():Vector4
	{
		return new Vector4(1, 0, 0);
	}

	private inline static function get_Y_AXIS():Vector4
	{
		return new Vector4(0, 1, 0);
	}

	private inline static function get_Z_AXIS():Vector4
	{
		return new Vector4(0, 0, 1);
	}
}
