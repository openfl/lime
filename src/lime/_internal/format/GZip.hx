package lime._internal.format;

import haxe.io.Bytes;
import lime._internal.backend.native.NativeCFFI;
#if flash
import haxe.crypto.Crc32;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class GZip
{
	/**
		Compresses `bytes`. `level` is 0 to 9, from storing the data to the best compression,
		or -1 for this target's default. Flash ignores it.
	**/
	public static function compress(bytes:Bytes, level:Int = -1):Bytes
	{
		if (level < -1) level = 0;
		if (level > 9) level = 9;

		#if (lime_cffi && !macro)
		#if !cs
		return NativeCFFI.lime_gzip_compress_level(bytes, Bytes.alloc(0), level);
		#else
		var data:Dynamic = NativeCFFI.lime_gzip_compress_level(bytes, null, level);
		if (data == null) return null;
		return @:privateAccess new Bytes(data.length, data.b);
		#end
		#elseif js
		#if commonjs
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("require (\"pako\").gzip")(bytes.getData(), level < 0 ? null : {level: level});
		#else
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("pako.gzip")(bytes.getData(), level < 0 ? null : {level: level});
		#end
		return Bytes.ofData(data);
		#elseif flash
		// A gzip member is a raw deflate stream between a header and a trailer (RFC 1952)
		var deflated = Deflate.compress(bytes);
		if (deflated == null) return null;

		var data = Bytes.alloc(10 + deflated.length + 8);
		data.set(0, 0x1F);
		data.set(1, 0x8B);
		data.set(2, 8); // CM: deflate
		data.set(3, 0); // FLG: no optional fields
		data.setInt32(4, 0); // MTIME: none
		data.set(8, 0); // XFL
		data.set(9, 0xFF); // OS: unknown
		data.blit(10, deflated, 0, deflated.length);
		data.setInt32(10 + deflated.length, Crc32.make(bytes));
		data.setInt32(14 + deflated.length, bytes.length);
		return data;
		#else
		return null;
		#end
	}

	public static function decompress(bytes:Bytes):Bytes
	{
		#if (lime_cffi && !macro)
		#if !cs
		return NativeCFFI.lime_gzip_decompress(bytes, Bytes.alloc(0));
		#else
		var data:Dynamic = NativeCFFI.lime_gzip_decompress(bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes(data.length, data.b);
		#end
		#elseif js
		return PakoInflate.inflate(bytes, PakoInflate.GZIP);
		#elseif flash
		return __flashDecompress(bytes);
		#else
		return null;
		#end
	}

	#if flash
	// Reads the gzip members one after another, giving null for anything that isn't one or whose CRC-32 or size
	// doesn't match what it inflates to (RFC 1952). Flash doesn't say where a member's deflate stream ends, so
	// each place it could, the end of the data or another member's header, is tried against the trailer.
	private static function __flashDecompress(bytes:Bytes):Bytes
	{
		var output = new haxe.io.BytesBuffer();
		var position = 0;

		do
		{
			var start = __flashMemberStart(bytes, position);
			if (start < 0) return null;

			var next = -1;
			var trailer = start;

			while (trailer + 8 <= bytes.length)
			{
				var end = trailer + 8;

				if (end == bytes.length || (end + 3 <= bytes.length && bytes.get(end) == 0x1F && bytes.get(end + 1) == 0x8B && bytes.get(end + 2) == 8))
				{
					var inflated = __flashInflate(bytes, start, trailer);

					if (inflated != null)
					{
						output.add(inflated);
						next = end;
						break;
					}
				}

				trailer++;
			}

			if (next < 0) return null;
			position = next;
		}
		while (position < bytes.length);

		return output.getBytes();
	}

	// Where the deflate stream of the member at position starts, past its header, or -1
	private static function __flashMemberStart(bytes:Bytes, position:Int):Int
	{
		var length = bytes.length;
		if (length - position < 18 || bytes.get(position) != 0x1F || bytes.get(position + 1) != 0x8B || bytes.get(position + 2) != 8) return -1;

		var flags = bytes.get(position + 3);
		if (flags & 0xE0 != 0) return -1;

		position += 10;
		var end = length - 8;

		// FEXTRA, FNAME, FCOMMENT and FHCRC, in that order
		if (flags & 4 != 0)
		{
			if (position + 2 > end) return -1;
			position += 2 + (bytes.get(position) | (bytes.get(position + 1) << 8));
		}

		for (flag in [8, 16])
		{
			if (flags & flag != 0)
			{
				while (position < end && bytes.get(position) != 0)
				{
					position++;
				}

				position++;
			}
		}

		if (flags & 2 != 0) position += 2;
		return position > end ? -1 : position;
	}

	// The member's data when the deflate stream from start to trailer inflates to what the trailer says, or null
	private static function __flashInflate(bytes:Bytes, start:Int, trailer:Int):Bytes
	{
		var inflated:Bytes = null;

		try
		{
			inflated = Deflate.decompress(bytes.sub(start, trailer - start));
		}
		catch (e:Dynamic)
		{
			return null;
		}

		if (inflated == null || bytes.getInt32(trailer) != Crc32.make(inflated) || bytes.getInt32(trailer + 4) != inflated.length) return null;

		return inflated;
	}
	#end
}
