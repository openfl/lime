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
		var byteArray:ByteArray = cast bytes.getData();

		var data = new ByteArray();
		data.writeBytes(byteArray);
		data.uncompress();

		return Bytes.ofData(data);
		#else
		return null;
		#end
	}
}
