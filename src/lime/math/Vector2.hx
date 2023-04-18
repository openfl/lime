package lime.math;

#if flash
import flash.geom.Point;
#end

/**
	The `Vector2` class can be used for calculating math with
	basic (x, y) coordinates
**/
#if hl
@:keep
#end
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Vector2
{
	/**
		Gets the length of this vector from (0, 0) to (x, y)
	**/
	public var length(get, never):Float;

	/**
		Gets the square of the length of this vector, which
		avoids use of `Math.sqrt` for faster performance
	**/
	public var lengthSquared(get, never):Float;

	/**
		The x coodinate for this vector
	**/
	public var x:Float;

	/**
		The y coodinate for this vector
	**/
	public var y:Float;

	/**
		Creates a new `Vector` instance
		@param	x	(Optional) An initial `x` value (default is 0)
		@param	y	(Optional) An initial `y` value (default is 0)
	**/
	public function new(x:Float = 0, y:Float = 0)
	{
		this.x = x;
		this.y = y;
	}

	/**
		Adds the current vector to a second `Vector2` instance
		and returns the result
		@param	v	A `Vector2` instance to add
		@param	result	(Optional) A `Vector2` instance to store the result
		@return	A `Vector2` instance that combines both vector values
	**/
	public function add(v:Vector2, result:Vector2 = null):Vector2
	{
		if (result == null) result = new Vector2();
		result.setTo(v.x + x, v.y + y);
		return result;
	}

	/**
		Clones the current `Vector2`
		@return	A new `Vector2` instance with the same values as the current one
	**/
	public function clone():Vector2
	{
		return new Vector2(x, y);
	}

	/**
		Calculates the distance between two `Vector2` points
		@param	pt1	A `Vector2` instance
		@param	pt2	A second `Vector2` instance
		@return	The distance between each `Vector2`
	**/
	public static function distance(pt1:Vector2, pt2:Vector2):Float
	{
		var dx = pt1.x - pt2.x;
		var dy = pt1.y - pt2.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	/**
		Whether this `Vector2` has the same values as another instance
		@param	toCompare	A `Vector2` instance to compare against
		@return	Whether the values of each vector are equal
	**/
	public function equals(toCompare:Vector2):Bool
	{
		return toCompare != null && toCompare.x == x && toCompare.y == y;
	}

	/**
		Interpolates between two points, given a specified percentage value
		@param	pt1	A `Vector2` instance
		@param	pt2	A second `Vector2` instance
		@param	f	A percentage value to interpolate
		@param	result	(Optional) A `Vector2` instance to use for the result
		@return	A `Vector2` instance holding the interpolated value
	**/
	public static function interpolate(pt1:Vector2, pt2:Vector2, f:Float, result:Vector2 = null):Vector2
	{
		if (result == null) result = new Vector2();
		result.setTo(pt2.x + f * (pt1.x - pt2.x), pt2.y + f * (pt1.y - pt2.y));
		return result;
	}

	/**
		Normalizes this vector between the current length and a set scale value
		@param	thickness	The scaling value. . For example, if the current vector is `(0, 5)` and you normalize it to 1, the normalized value will be `(0, 1)`
	**/
	public function normalize(thickness:Float):Void
	{
		if (x == 0 && y == 0)
		{
			return;
		}
		else
		{
			var norm = thickness / Math.sqrt(x * x + y * y);
			x *= norm;
			y *= norm;
		}
	}

	/**
		Offsets the current value of this vector
		@param	dx	An offset x value
		@param	dy	An offset y value
	**/
	public function offset(dx:Float, dy:Float):Void
	{
		x += dx;
		y += dy;
	}

	/**
		Converts a polar coordinate to into a cartesian `Vector2` instance
		@param	len	The length of the polar value
		@param	angle	The angle of the polar value
		@param	result	(Optional) A `Vector2` instance to store the result
		@return	A `Vector2` instance in cartesian coordinates
	**/
	public static function polar(len:Float, angle:Float, result:Vector2 = null):Vector2
	{
		if (result == null) result = new Vector2();
		result.setTo(len * Math.cos(angle), len * Math.sin(angle));
		return result;
	}

	/**
		Sets this `Vector2` to new values
		@param	xa	An `x` value
		@param	ya	A `y` value
	**/
	public inline function setTo(xa:Float, ya:Float):Void
	{
		x = xa;
		y = ya;
	}

	/**
		Subtracts the current vector from another `Vector2` instance
		@param	v	A `Vector2` instance to subtract from the current vector
		@param	result	(Optional) A `Vector2` instance to store the result
		@return	A `Vector2` instance containing the subtracted values
	**/
	public function subtract(v:Vector2, result:Vector2 = null):Vector2
	{
		if (result == null) result = new Vector2();
		result.setTo(x - v.x, y - v.y);
		return result;
	}

	@:noCompletion private function __toFlashPoint():#if flash Point #else Dynamic #end
	{
		#if flash
		return new Point(x, y);
		#else
		return null;
		#end
	}

	// Getters & Setters
	@:noCompletion private function get_length():Float
	{
		return Math.sqrt(x * x + y * y);
	}

	@:noCompletion private function get_lengthSquared():Float
	{
		return (x * x + y * y);
	}
}
