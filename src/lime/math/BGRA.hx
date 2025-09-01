package lime.math;

import lime.graphics.PixelFormat;
import lime.utils.UInt32Array;
import lime.utils.UInt8Array;

/**
	A utility for storing, accessing and converting colors in a BGRA
	(blue, green, red, alpha) color format.

	```haxe
	var color:BGRA = 0x003388FF;
	trace (color.b); // 0x00
	trace (color.g); // 0x33
	trace (color.r); // 0x88
	trace (color.a); // 0xFF

	var convert:ARGB = color; // 0xFF883300
	```
**/
@:transitive
abstract BGRA(#if (flash && !lime_doc_gen) Int #else UInt #end) from Int to Int from UInt to UInt
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
		Creates a new BGRA instance
		@param	bgra	(Optional) A BGRA color value
	**/
	public inline function new(bgra:Int = 0)
	{
		this = bgra;
	}

	/**
		Creates a new BGRA instance from component values
		@param	b	A blue component value
		@param	g	A green component value
		@param	r	A red component value
		@param	a	An alpha component value
		@return	A new BGRA instance
	**/
	public static inline function create(b:Int, g:Int, r:Int, a:Int):BGRA
	{
		var bgra = new BGRA();
		bgra.set(b, g, r, a);
		return bgra;
	}

	/**
		Multiplies the red, green and blue components by the current alpha component
	**/
	public inline function multiplyAlpha()
	{
		if (a == 0)
		{
			this = 0;
		}
		else if (a != 0xFF)
		{
			a16 = RGBA.__alpha16[a];
			set((b * a16) >> 16, (g * a16) >> 16, (r * a16) >> 16, a);
		}
	}

	/**
		Reads a value from a `UInt8Array` into the current `BGRA` color
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
				set(data[offset], data[offset + 1], data[offset + 2], data[offset + 3]);

			case RGBA32:
				set(data[offset + 2], data[offset + 1], data[offset], data[offset + 3]);

			case ARGB32:
				set(data[offset + 3], data[offset + 2], data[offset + 1], data[offset]);
		}

		if (premultiplied)
		{
			unmultiplyAlpha();
		}
	}

	/**
		Sets the current `BGRA` color to new component values
		@param	b	The blue component vlaue to set
		@param	g	The green component value to set
		@param	r	The red component value to set
		@param	a	The alpha component value to set
	**/
	public inline function set(b:Int, g:Int, r:Int, a:Int):Void
	{
		this = ((b & 0xFF) << 24) | ((g & 0xFF) << 16) | ((r & 0xFF) << 8) | (a & 0xFF);
	}

	/**
		Divides the current red, green and blue components by the alpha component
	**/
	public inline function unmultiplyAlpha()
	{
		if (a != 0 && a != 0xFF)
		{
			unmult = 255.0 / a;
			set(RGBA.__clamp[Math.floor(b * unmult)], RGBA.__clamp[Math.floor(g * unmult)], RGBA.__clamp[Math.floor(r * unmult)], a);
		}
	}

	/**
		Writes the current `BGRA` color into a `UInt8Array`
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

	@:from private static inline function __fromARGB(argb:ARGB):BGRA
	{
		return BGRA.create(argb.b, argb.g, argb.r, argb.a);
	}

	@:from private static inline function __fromRGBA(rgba:RGBA):BGRA
	{
		return BGRA.create(rgba.b, rgba.g, rgba.r, rgba.a);
	}

	// Get & Set Methods
	@:noCompletion private inline function get_a():Int
	{
		return this & 0xFF;
	}

	@:noCompletion private inline function set_a(value:Int):Int
	{
		set(b, g, r, value);
		return value;
	}

	@:noCompletion private inline function get_b():Int
	{
		return (this >> 24) & 0xFF;
	}

	@:noCompletion private inline function set_b(value:Int):Int
	{
		set(value, g, r, a);
		return value;
	}

	@:noCompletion private inline function get_g():Int
	{
		return (this >> 16) & 0xFF;
	}

	@:noCompletion private inline function set_g(value:Int):Int
	{
		set(b, value, r, a);
		return value;
	}

	@:noCompletion private inline function get_r():Int
	{
		return (this >> 8) & 0xFF;
	}

	@:noCompletion private inline function set_r(value:Int):Int
	{
		set(b, g, value, a);
		return value;
	}
}
