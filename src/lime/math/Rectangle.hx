package lime.math;

#if flash
import flash.geom.Rectangle as FlashRectangle;
#end

/**
	The `Rectangle` class provides a simple object for storing
	and manipulating a logical rectangle for calculations
**/
#if hl
@:keep
#end
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Rectangle
{
	/**
		Get or set the bottom (y + height) value of the `Rectangle`
	**/
	public var bottom(get, set):Float;

	/**
		Get or set the bottom-right (x + width, y + height) as a `Vector2`
	**/
	public var bottomRight(get, set):Vector2;

	/**
		Get or set the height of the rectangle
	**/
	public var height:Float;

	/**
		Get or set the left (x) of the rectangle
	**/
	public var left(get, set):Float;

	/**
		Get or set the right (x + width) of the rectangle
	**/
	public var right(get, set):Float;

	/**
		Get or set the size (width, height) as a `Vector2`
	**/
	public var size(get, set):Vector2;

	/**
		Get or set the top (y) of the rectangle
	**/
	public var top(get, set):Float;

	/**
		Get or set the top-left (x, y) as a `Vector2`
	**/
	public var topLeft(get, set):Vector2;

	/**
		Get or set the width of the rectangle
	**/
	public var width:Float;

	/**
		Get or set the x of the rectangle
	**/
	public var x:Float;

	/**
		Get or set the y of the rectangle
	**/
	public var y:Float;

	/**
		Create a new `Rectangle` instance
		@param	x	(Optional) Initial x value (default is 0)
		@param	y	(Optional) Initial y value (default is 0)
		@param	width	(Optional) Initial width value (default is 0)
		@param	height	(Optional) Initial height value (default is 0)
	**/
	public function new(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0):Void
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}

	/**
		Creates a clone of this `Rectangle`
		@return	A new `Rectangle` instance
	**/
	public function clone():Rectangle
	{
		return new Rectangle(x, y, width, height);
	}

	/**
		Returns whether this rectangle contains the specified (x, y) point
		@param	x	The x coordinate to test
		@param	y	The y coordinate to test
		@return	Whether the point is contained in the rectangle
	**/
	public function contains(x:Float, y:Float):Bool
	{
		return x >= this.x && y >= this.y && x < right && y < bottom;
	}

	@:dox(hide) @:noCompletion @:deprecated("Use containsVector") public function containsPoint(point:Vector2):Bool
	{
		return containsVector(point);
	}

	/**
		Returns whether this rectangle contains another rectangle
		This will return `false` if the second rectangle only
		overlaps but is not fully contained within the current rectangle
		@param	rect	A second `Rectangle` instance to test
		@return	Whether the `rect` is contained within the current `Rectangle`
	**/
	public function containsRect(rect:Rectangle):Bool
	{
		if (rect.width <= 0 || rect.height <= 0)
		{
			return rect.x > x && rect.y > y && rect.right < right && rect.bottom < bottom;
		}
		else
		{
			return rect.x >= x && rect.y >= y && rect.right <= right && rect.bottom <= bottom;
		}
	}

	/**
		Returns whether this rectangle contains the specified vector
		@param	vector	The vector to test
		@return	Whether the vector is contained in the rectangle
	**/
	public function containsVector(vector:Vector2):Bool
	{
		return contains(vector.x, vector.y);
	}

	/**
		Copies the x, y, width and height of another `Rectangle`
		@param	sourceRect	Another `Rectangle` instance
	**/
	public function copyFrom(sourceRect:Rectangle):Void
	{
		x = sourceRect.x;
		y = sourceRect.y;
		width = sourceRect.width;
		height = sourceRect.height;
	}

	/**
		Checks whether the current `Rectangle` and another
		instance have equal values
		@param	toCompare	Another `Rectangle` to compare with
		@return	Whether both rectangles are not `null` and have equal values
	**/
	public function equals(toCompare:Rectangle):Bool
	{
		return toCompare != null && x == toCompare.x && y == toCompare.y && width == toCompare.width && height == toCompare.height;
	}

	/**
		Increases the size of the current rectangle by
		the given delta x and y values
		@param	dx	A delta x value to increase the size by
		@param	dy	A delta y value to increase the size by
	**/
	public function inflate(dx:Float, dy:Float):Void
	{
		x -= dx;
		width += dx * 2;
		y -= dy;
		height += dy * 2;
	}

	/**
		Increases the size of the current rectangle by
		the given delta vector values
		@param	vector	A delta vector to increase the size by
	**/
	public function inflateVector(vector:Vector2):Void
	{
		inflate(vector.x, vector.y);
	}

	/**
		Returns a new rectangle with the area where the current
		`Rectangle` and another `Rectangle` instance overlap.
		If they do not overlap, the returned `Rectangle` will
		be empty
		@param	toIntersect	Another `Rectangle` instance to intersect with
		@param	result	(Optional) A `Rectangle` instance to use for the result
		@return	A `Rectangle` of the intersection area
	**/
	public function intersection(toIntersect:Rectangle, result:Rectangle = null):Rectangle
	{
		if (result == null) result = new Rectangle();

		var x0 = x < toIntersect.x ? toIntersect.x : x;
		var x1 = right > toIntersect.right ? toIntersect.right : right;

		if (x1 <= x0)
		{
			result.setEmpty();
			return result;
		}

		var y0 = y < toIntersect.y ? toIntersect.y : y;
		var y1 = bottom > toIntersect.bottom ? toIntersect.bottom : bottom;

		if (y1 <= y0)
		{
			result.setEmpty();
			return result;
		}

		result.x = x0;
		result.y = y0;
		result.width = x1 - x0;
		result.height = y1 - y0;
		return result;
	}

	/**
		Returns if the current `Rectangle` overlaps with another instance
		@param	toIntersect	Another `Rectangle` to compare with
		@return	Whether the rectangles intersect
	**/
	public function intersects(toIntersect:Rectangle):Bool
	{
		var x0 = x < toIntersect.x ? toIntersect.x : x;
		var x1 = right > toIntersect.right ? toIntersect.right : right;

		if (x1 <= x0)
		{
			return false;
		}

		var y0 = y < toIntersect.y ? toIntersect.y : y;
		var y1 = bottom > toIntersect.bottom ? toIntersect.bottom : bottom;

		return y1 > y0;
	}

	/**
		Whether this rectangle is empty
		@return	`true` if the width or height is <= 0
	**/
	public function isEmpty():Bool
	{
		return (width <= 0 || height <= 0);
	}

	/**
		Moves the rectangle by offset x and values
		@param	dx	A delta x value
		@param	dy	A delta y value
	**/
	public function offset(dx:Float, dy:Float):Void
	{
		x += dx;
		y += dy;
	}

	/**
		Moves the rectangle by the values of a `Vector2`
		@param	dx	A delta vector
	**/
	public function offsetVector(vector:Vector2):Void
	{
		x += vector.x;
		y += vector.y;
	}

	/**
		Makes this rectangle empty
	**/
	public function setEmpty():Void
	{
		x = y = width = height = 0;
	}

	/**
		Sets the values of this rectangle at once
		@param	xa	A new x value
		@param	ya	A new y value
		@param	widtha	A new width value
		@param	heighta	A new height value
	**/
	public function setTo(xa:Float, ya:Float, widtha:Float, heighta:Float):Void
	{
		x = xa;
		y = ya;
		width = widtha;
		height = heighta;
	}

	/**
		Combines two rectangles together, returning the
		minimum `Rectangle` that contains both rectangles
		@param	toUnion	A second `Rectangle` to unify
		@param	result	(Optional) A `Rectangle` instance for the result
		@return	A `Rectangle` that contains the dimensions of both rectangles
	**/
	public function union(toUnion:Rectangle, result:Rectangle = null):Rectangle
	{
		if (result == null) result = new Rectangle();

		if (width == 0 || height == 0)
		{
			result.copyFrom(toUnion);
		}
		else if (toUnion.width == 0 || toUnion.height == 0)
		{
			result.copyFrom(this);
		}
		else
		{
			var x0 = x > toUnion.x ? toUnion.x : x;
			var x1 = right < toUnion.right ? toUnion.right : right;
			var y0 = y > toUnion.y ? toUnion.y : y;
			var y1 = bottom < toUnion.bottom ? toUnion.bottom : bottom;

			result.setTo(x0, y0, x1 - x0, y1 - y0);
		}

		return result;
	}

	@:noCompletion private function __toFlashRectangle():#if flash FlashRectangle #else Dynamic #end
	{
		#if flash
		return new FlashRectangle(x, y, width, height);
		#else
		return null;
		#end
	}

	// Getters & Setters
	@:noCompletion private function get_bottom():Float
	{
		return y + height;
	}

	@:noCompletion private function set_bottom(b:Float):Float
	{
		height = b - y;
		return b;
	}

	@:noCompletion private function get_bottomRight():Vector2
	{
		return new Vector2(x + width, y + height);
	}

	@:noCompletion private function set_bottomRight(p:Vector2):Vector2
	{
		width = p.x - x;
		height = p.y - y;
		return p.clone();
	}

	@:noCompletion private function get_left():Float
	{
		return x;
	}

	@:noCompletion private function set_left(l:Float):Float
	{
		width -= l - x;
		x = l;
		return l;
	}

	@:noCompletion private function get_right():Float
	{
		return x + width;
	}

	@:noCompletion private function set_right(r:Float):Float
	{
		width = r - x;
		return r;
	}

	@:noCompletion private function get_size():Vector2
	{
		return new Vector2(width, height);
	}

	@:noCompletion private function set_size(p:Vector2):Vector2
	{
		width = p.x;
		height = p.y;
		return p.clone();
	}

	@:noCompletion private function get_top():Float
	{
		return y;
	}

	@:noCompletion private function set_top(t:Float):Float
	{
		height -= t - y;
		y = t;
		return t;
	}

	@:noCompletion private function get_topLeft():Vector2
	{
		return new Vector2(x, y);
	}

	@:noCompletion private function set_topLeft(p:Vector2):Vector2
	{
		x = p.x;
		y = p.y;
		return p.clone();
	}
}
