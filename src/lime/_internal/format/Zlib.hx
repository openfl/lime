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
	public static function compress(bytes:Bytes):Bytes
	{
		#if (lime_cffi && !macro)
		#if !cs
		return NativeCFFI.lime_zlib_compress(bytes, Bytes.alloc(0));
		#else
		var data:Dynamic = NativeCFFI.lime_zlib_compress(bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes(data.length, data.b);
		#end
		#elseif js
		#if commonjs
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("require (\"pako\").deflate")(bytes.getData());
		#else
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("pako.deflate")(bytes.getData());
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
		#if commonjs
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("require (\"pako\").inflate")(bytes.getData());
		#else
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("pako.inflate")(bytes.getData());
		#end
		return Bytes.ofData(data);
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
