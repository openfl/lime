package lime._internal.format;

import haxe.io.Bytes;
import lime._internal.backend.native.NativeCFFI;
#if flash
import flash.utils.ByteArray;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class Zlib
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
		return NativeCFFI.lime_zlib_compress_level(bytes, Bytes.alloc(0), level);
		#else
		var data:Dynamic = NativeCFFI.lime_zlib_compress_level(bytes, null, level);
		if (data == null) return null;
		return @:privateAccess new Bytes(data.length, data.b);
		#end
		#elseif js
		#if commonjs
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("require (\"pako\").deflate")(bytes.getData(), level < 0 ? null : {level: level});
		#else
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("pako.deflate")(bytes.getData(), level < 0 ? null : {level: level});
		#end
		return Bytes.ofData(data);
		#elseif flash
		// Flash compresses nothing to nothing, where a stream needs its header, final block and Adler-32
		if (bytes.length == 0) return __bytes([0x78, 0x9C, 0x03, 0x00, 0x00, 0x00, 0x00, 0x01]);

		var byteArray:ByteArray = cast bytes.getData();

		var data = new ByteArray();
		data.writeBytes(byteArray);
		data.compress();

		return Bytes.ofData(data);
		#else
		return null;
		#end
	}

	public static function decompress(bytes:Bytes):Bytes
	{
		#if (lime_cffi && !macro)
		#if !cs
		return NativeCFFI.lime_zlib_decompress(bytes, Bytes.alloc(0));
		#else
		var data:Dynamic = NativeCFFI.lime_zlib_decompress(bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes(data.length, data.b);
		#end
		#elseif js
		return PakoInflate.inflate(bytes, PakoInflate.ZLIB);
		#elseif flash
		// Flash uncompresses nothing to nothing, but a stream has at least its header
		if (bytes.length == 0) return null;

		var byteArray:ByteArray = cast bytes.getData();

		var data = new ByteArray();
		data.writeBytes(byteArray);
		data.uncompress();

		return Bytes.ofData(data);
		#else
		return null;
		#end
	}

	#if flash
	private static function __bytes(values:Array<Int>):Bytes
	{
		var bytes = Bytes.alloc(values.length);
		for (i in 0...values.length) bytes.set(i, values[i]);
		return bytes;
	}
	#end
}
