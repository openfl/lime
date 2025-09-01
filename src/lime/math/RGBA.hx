package lime.math;

import lime.graphics.PixelFormat;
import lime.utils.UInt32Array;
import lime.utils.UInt8Array;

/**
	A utility for storing, accessing and converting colors in an RGBA
	(red, green, blue, alpha) color format.

	```haxe
	var color:RGBA = 0x883300FF;
	trace (color.r); // 0x88
	trace (color.g); // 0x33
	trace (color.b); // 0x00
	trace (color.a); // 0xFF

	var convert:ARGB = color; // 0xFF883300
	```
**/
@:allow(lime.math)
@:transitive
abstract RGBA(#if (flash && !lime_doc_gen) Int #else UInt #end) from Int to Int from UInt to UInt
{
	private static var __alpha16:UInt32Array;
	private static var __clamp:UInt8Array;
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

	private static function __init__():Void
	{
		#if (js && modular)
		__initColors();
		#else
		__alpha16 = new UInt32Array(256);

		for (i in 0...256)
		{
			__alpha16[i] = Math.ceil((i) * ((1 << 16) / 0xFF));
		}

		__clamp = new UInt8Array(0xFF + 0xFF + 1);

		for (i in 0...0xFF)
		{
			__clamp[i] = i;
		}

		for (i in 0xFF...(0xFF + 0xFF + 1))
		{
			__clamp[i] = 0xFF;
		}
		#end
	}

	#if (js && modular)
	private static function __initColors()
	{
		__alpha16 = new UInt32Array(256);

		for (i in 0...256)
		{
			__alpha16[i] = Math.ceil((i) * ((1 << 16) / 0xFF));
		}

		__clamp = new UInt8Array(0xFF + 0xFF);

		for (i in 0...0xFF)
		{
			__clamp[i] = i;
		}

		for (i in 0xFF...(0xFF + 0xFF + 1))
		{
			__clamp[i] = 0xFF;
		}
	}
	#end

	/**
		Creates a new RGBA instance
		@param	rgba	(Optional) An RGBA color value
	**/
	public inline function new(rgba:Int = 0)
	{
		this = rgba;
	}

	/**
		Creates a new RGBA instance from component values
		@param	r	A red component value
		@param	g	A green component value
		@param	b	A blue component value
		@param	a	An alpha component value
		@return	A new RGBA instance
	**/
	public static inline function create(r:Int, g:Int, b:Int, a:Int):RGBA
	{
		var rgba = new RGBA();
		rgba.set(r, g, b, a);
		return rgba;
	}

	/**
		Multiplies the red, green and blue components by the current alpha component
	**/
	public inline function multiplyAlpha()
	{
		if (a == 0)
		{
			if (this != 0)
			{
				this = 0;
			}
		}
		else if (a != 0xFF)
		{
			a16 = __alpha16[a];
			set((r * a16) >> 16, (g * a16) >> 16, (b * a16) >> 16, a);
		}
	}

	/**
		Reads a value from a `UInt8Array` into the current `RGBA` color
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
				set(data[offset + 2], data[offset + 1], data[offset], data[offset + 3]);

			case RGBA32:
				set(data[offset], data[offset + 1], data[offset + 2], data[offset + 3]);

			case ARGB32:
				set(data[offset + 1], data[offset + 2], data[offset + 3], data[offset]);
		}

		if (premultiplied)
		{
			unmultiplyAlpha();
		}
	}

	/**
		Sets the current `RGBA` color to new component values
		@param	r	The red component value to set
		@param	g	The green component value to set
		@param	b	The blue component vlaue to set
		@param	a	The alpha component value to set
	**/
	public inline function set(r:Int, g:Int, b:Int, a:Int):Void
	{
		this = ((r & 0xFF) << 24) | ((g & 0xFF) << 16) | ((b & 0xFF) << 8) | (a & 0xFF);
	}

	/**
		Divides the current red, green and blue components by the alpha component
	**/
	public inline function unmultiplyAlpha()
	{
		if (a != 0 && a != 0xFF)
		{
			unmult = 255.0 / a;
			set(__clamp[Math.round(r * unmult)], __clamp[Math.round(g * unmult)], __clamp[Math.round(b * unmult)], a);
		}
	}

	/**
		Writes the current `RGBA` color into a `UInt8Array`
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

	@:from private static inline function __fromARGB(argb:ARGB):RGBA
	{
		return RGBA.create(argb.r, argb.g, argb.b, argb.a);
	}

	@:from private static inline function __fromBGRA(bgra:BGRA):RGBA
	{
		return RGBA.create(bgra.r, bgra.g, bgra.b, bgra.a);
	}

	// Get & Set Methods
	@:noCompletion private inline function get_a():Int
	{
		return this & 0xFF;
	}

	@:noCompletion private inline function set_a(value:Int):Int
	{
		set(r, g, b, value);
		return value;
	}

	@:noCompletion private inline function get_b():Int
	{
		return (this >> 8) & 0xFF;
	}

	@:noCompletion private inline function set_b(value:Int):Int
	{
		set(r, g, value, a);
		return value;
	}

	@:noCompletion private inline function get_g():Int
	{
		return (this >> 16) & 0xFF;
	}

	@:noCompletion private inline function set_g(value:Int):Int
	{
		set(r, value, b, a);
		return value;
	}

	@:noCompletion private inline function get_r():Int
	{
		return (this >> 24) & 0xFF;
	}

	@:noCompletion private inline function set_r(value:Int):Int
	{
		set(value, g, b, a);
		return value;
	}
}
