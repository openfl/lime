package lime._internal.format;

import haxe.io.Bytes;
import lime._internal.backend.native.NativeCFFI;
#if flash
import flash.utils.CompressionAlgorithm;
import flash.utils.ByteArray;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class LZMA
{
	#if js
	// LZMA-JS gives bytes as an array of signed values
	private static function __jsBytes(data:Dynamic):Bytes
	{
		var bytes:Dynamic = untyped #if haxe4 js.Syntax.code #else __js__ #end ("new Uint8Array({0})", data);
		return Bytes.ofData(bytes.buffer);
	}
	#end

	public static function compress(bytes:Bytes):Bytes
	{
		#if (lime_cffi && !macro)
		#if !cs
		return NativeCFFI.lime_lzma_compress(bytes, Bytes.alloc(0));
		#else
		var data:Dynamic = NativeCFFI.lime_lzma_compress(bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes(data.length, data.b);
		#end
		#elseif js
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("LZMA.compress")(@:privateAccess bytes.b, 5);
		return __jsBytes(data);
		#elseif flash
		var byteArray:ByteArray = cast bytes.getData();

		var data = new ByteArray();
		data.writeBytes(byteArray);
		data.compress(CompressionAlgorithm.LZMA);

		return Bytes.ofData(data);
		#else
		return null;
		#end
	}

	public static function decompress(bytes:Bytes):Bytes
	{
		#if (lime_cffi && !macro)
		#if !cs
		return NativeCFFI.lime_lzma_decompress(bytes, Bytes.alloc(0));
		#else
		var data:Dynamic = NativeCFFI.lime_lzma_decompress(bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes(data.length, data.b);
		#end
		#elseif js
		// The header's size is all ones when it isn't known. LZMA-JS stops at an end marker without checking it
		// against a known size, and reads a size of 0 as unknown.
		if (bytes.length < 13) return null;
		var sizeKnown = (bytes.getInt32(5) != -1 || bytes.getInt32(9) != -1);
		if (sizeKnown && (bytes.getInt32(9) != 0 || bytes.getInt32(5) < 0)) return null;
		if (sizeKnown && bytes.getInt32(5) == 0) return Bytes.alloc(0);

		var data:Dynamic = null;

		try
		{
			// decompress() would give a string when the bytes happen to read as UTF-8
			data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("LZMA.decompressBytes")(@:privateAccess bytes.b);
		}
		catch (e:Dynamic)
		{
			return null;
		}

		if (sizeKnown && data.length != bytes.getInt32(5)) return null;
		return __jsBytes(data);
		#elseif flash
		var byteArray:ByteArray = cast bytes.getData();

		var data = new ByteArray();
		data.writeBytes(byteArray);
		data.uncompress(CompressionAlgorithm.LZMA);

		return Bytes.ofData(data);
		#else
		return null;
		#end
	}
}
