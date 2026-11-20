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
	public static function compress(bytes:Bytes):Bytes
	{
		#if (lime_cffi && !macro)
		#if !cs
		return NativeCFFI.lime_gzip_compress(bytes, Bytes.alloc(0));
		#else
		var data:Dynamic = NativeCFFI.lime_gzip_compress(bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes(data.length, data.b);
		#end
		#elseif js
		#if commonjs
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("require (\"pako\").gzip")(bytes.getData());
		#else
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("pako.gzip")(bytes.getData());
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
	// Reads one gzip member, giving null for anything that isn't one or whose
	// CRC-32 or size doesn't match what it inflates to (RFC 1952)
	private static function __flashDecompress(bytes:Bytes):Bytes
	{
		var length = bytes.length;
		if (length < 18 || bytes.get(0) != 0x1F || bytes.get(1) != 0x8B || bytes.get(2) != 8) return null;

		var flags = bytes.get(3);
		if (flags & 0xE0 != 0) return null;

		var position = 10;
		var end = length - 8;

		// FEXTRA, FNAME, FCOMMENT and FHCRC, in that order
		if (flags & 4 != 0)
		{
			if (position + 2 > end) return null;
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
		if (position > end) return null;

		var inflated:Bytes = null;

		try
		{
			inflated = Deflate.decompress(bytes.sub(position, end - position));
		}
		catch (e:Dynamic)
		{
			return null;
		}

		if (inflated == null || bytes.getInt32(end) != Crc32.make(inflated) || bytes.getInt32(end + 4) != inflated.length) return null;

		return inflated;
	}
	#end
}
