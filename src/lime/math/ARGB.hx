package lime.math;

import lime.graphics.PixelFormat;
import lime.utils.UInt32Array;
import lime.utils.UInt8Array;

/**
	A utility for storing, accessing and converting colors in an ARGB
	(alpha, red, green, blue) color format.

	```haxe
	var color:ARGB = 0xFF883300;
	trace (color.a); // 0xFF
	trace (color.r); // 0x88
	trace (color.g); // 0x33
	trace (color.b); // 0x00

	var convert:BGRA = color; // 0x003388FF
	```
**/
@:transitive
abstract ARGB(#if (flash && !lime_doc_gen) Int #else UInt #end) from Int to Int from UInt to UInt
{
	private static var a16:Int;
	private static var unmult:Float;

	/**
		Accesses the alpha component of the color
	**/
	public var a(get, set):Int;

	/**
		Accesses the blue component of the color
	**/
	public var b(get, set):Int;

	/**
		Accesses the green component of the color
	**/
	public var g(get, set):Int;

	/**
		Accesses the red component of the color
	**/
	public var r(get, set):Int;

	/**
		Creates a new ARGB instance
		@param	argb	(Optional) An ARGB color value
	**/
	public inline function new(argb:Int = 0)
	{
		this = argb;
	}

	/**
		Creates a new ARGB instance from component values
		@param	a	An alpha component value
		@param	r	A red component value
		@param	g	A green component value
		@param	b	A blue component value
		@return	A new ARGB instance
	**/
	public static inline function create(a:Int, r:Int, g:Int, b:Int):ARGB
	{
		var argb = new ARGB();
		argb.set(a, r, g, b);
		return argb;
	}

	/**
		Multiplies the red, green and blue components by the current alpha component
	**/
	public inline function multiplyAlpha():Void
	{
		if (a == 0)
		{
			this = 0;
		}
		else if (a != 0xFF)
		{
			a16 = RGBA.__alpha16[a];
			set(a, (r * a16) >> 16, (g * a16) >> 16, (b * a16) >> 16);
		}
	}

	/**
		Reads a value from a `UInt8Array` into the current `ARGB` color
		@param	data	A `UInt8Array` instance
		@param	offset	An offset into the `UInt8Array` to read
		@param	format	(Optional) The `PixelFormat` represented by the `UInt8Array` data
		@param	premultiplied	(Optional) Whether the data is stored in premultiplied alpha format
	**/
	public inline function readUInt8(data:UInt8Array, offset:Int, format:PixelFormat = RGBA32, premultiplied:Bool = false):Void
	{
		switch (format)
		{
			case BGRA32:
				set(data[offset + 1], data[offset], data[offset + 3], data[offset + 2]);

			case RGBA32:
				set(data[offset + 1], data[offset + 2], data[offset + 3], data[offset]);

			case ARGB32:
				set(data[offset + 2], data[offset + 3], data[offset], data[offset + 1]);
		}

		if (premultiplied)
		{
			unmultiplyAlpha();
		}
	}

	/**
		Sets the current `ARGB` color to new component values
		@param	a	The alpha component value to set
		@param	r	The red component value to set
		@param	g	The green component value to set
		@param	b	The blue component vlaue to set
	**/
	public inline function set(a:Int, r:Int, g:Int, b:Int):Void
	{
		this = ((a & 0xFF) << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF);
	}

	/**
		Divides the current red, green and blue components by the alpha component
	**/
	public inline function unmultiplyAlpha()
	{
		if (a != 0 && a != 0xFF)
		{
			unmult = 255.0 / a;
			set(a, RGBA.__clamp[Math.floor(r * unmult)], RGBA.__clamp[Math.floor(g * unmult)], RGBA.__clamp[Math.floor(b * unmult)]);
		}
	}

	/**
		Writes the current `ARGB` color into a `UInt8Array`
		@param	data	A `UInt8Array` instance
		@param	offset	An offset into the `UInt8Array` to write
		@param	format	(Optional) The `PixelFormat` represented by the `UInt8Array` data
		@param	premultiplied	(Optional) Whether the data is stored in premultiplied alpha format
	**/
	public inline function writeUInt8(data:UInt8Array, offset:Int, format:PixelFormat = RGBA32, premultiplied:Bool = false):Void
	{
		if (premultiplied)
		{
			multiplyAlpha();
		}

		switch (format)
		{
			case BGRA32:
				data[offset] = b;
				data[offset + 1] = g;
				data[offset + 2] = r;
				data[offset + 3] = a;

			case RGBA32:
				data[offset] = r;
				data[offset + 1] = g;
				data[offset + 2] = b;
				data[offset + 3] = a;

			case ARGB32:
				data[offset] = a;
				data[offset + 1] = r;
				data[offset + 2] = g;
				data[offset + 3] = b;
		}
	}

	@:from private static inline function __fromBGRA(bgra:BGRA):ARGB
	{
		return ARGB.create(bgra.a, bgra.r, bgra.g, bgra.b);
	}

	@:from private static inline function __fromRGBA(rgba:RGBA):ARGB
	{
		return ARGB.create(rgba.a, rgba.r, rgba.g, rgba.b);
	}

	// Get & Set Methods
	@:noCompletion private inline function get_a():Int
	{
		return (this >> 24) & 0xFF;
	}

	@:noCompletion private inline function set_a(value:Int):Int
	{
		set(value, r, g, b);
		return value;
	}

	@:noCompletion private inline function get_b():Int
	{
		return this & 0xFF;
	}

	@:noCompletion private inline function set_b(value:Int):Int
	{
		set(a, r, g, value);
		return value;
	}

	@:noCompletion private inline function get_g():Int
	{
		return (this >> 8) & 0xFF;
	}

	@:noCompletion private inline function set_g(value:Int):Int
	{
		set(a, r, value, b);
		return value;
	}

	@:noCompletion private inline function get_r():Int
	{
		return (this >> 16) & 0xFF;
	}

	@:noCompletion private inline function set_r(value:Int):Int
	{
		set(a, value, g, b);
		return value;
	}
}
