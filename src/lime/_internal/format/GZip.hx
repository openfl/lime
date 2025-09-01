package lime._internal.format;

import haxe.io.Bytes;
import lime._internal.backend.native.NativeCFFI;

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
		#if commonjs
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("require (\"pako\").ungzip")(bytes.getData());
		#else
		var data = untyped #if haxe4 js.Syntax.code #else __js__ #end ("pako.ungzip")(bytes.getData());
		#end
		return Bytes.ofData(data);
		#else
		return null;
		#end
	}
}
