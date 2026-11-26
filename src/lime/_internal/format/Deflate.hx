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
class Deflate
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
		return NativeCFFI.lime_deflate_compress_level(bytes, Bytes.alloc(0), level);
		#else
		var data:Dynamic = NativeCFFI.lime_deflate_compress_level(bytes, null, level);
		if (data == null) return null;
		return @:privateAccess new Bytes(data.length, data.b);
		#end
		#elseif js
		#if commonjs
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("require (\"pako\").deflateRaw")(bytes.getData(), level < 0 ? null : {level: level});
		#else
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("pako.deflateRaw")(bytes.getData(), level < 0 ? null : {level: level});
		#end
		return Bytes.ofData(data);
		#elseif flash
		// Flash deflates nothing to nothing, where a stream needs its final block: an empty stored block
		if (bytes.length == 0) return __bytes([0x03, 0x00]);

		var byteArray:ByteArray = cast bytes.getData();

		var data = new ByteArray();
		data.writeBytes(byteArray);
		data.deflate();

		return Bytes.ofData(data);
		#else
		return null;
		#end
	}

	public static function decompress(bytes:Bytes):Bytes
	{
		#if (lime_cffi && !macro)
		#if !cs
		return NativeCFFI.lime_deflate_decompress(bytes, Bytes.alloc(0));
		#else
		var data:Dynamic = NativeCFFI.lime_deflate_decompress(bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes(data.length, data.b);
		#end
		#elseif js
		return PakoInflate.inflate(bytes, PakoInflate.DEFLATE);
		#elseif flash
		// Flash inflates nothing to nothing, but a stream has at least its final block
		if (bytes.length == 0) return null;

		var byteArray:ByteArray = cast bytes.getData();

		var data = new ByteArray();
		data.writeBytes(byteArray);
		data.inflate();

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
