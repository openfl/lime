package lime.utils.compress;


import haxe.io.Bytes;
import lime._backend.native.NativeCFFI;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)


class GZip {
	
	
	public static function compress (bytes:Bytes):Bytes {
		
		#if (lime_cffi && !macro)
		
		#if !cs
		return NativeCFFI.lime_gzip_compress (bytes, Bytes.alloc (0));
		#else
		var data:Dynamic = NativeCFFI.lime_gzip_compress (bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		#end
		
		#elseif (js && html5)
		
		var data = untyped __js__ ("pako.gzip") (bytes.getData ());
		return Bytes.ofData (data);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public static function decompress (bytes:Bytes):Bytes {
		
		#if (lime_cffi && !macro)
		
		#if !cs
		return NativeCFFI.lime_gzip_decompress (bytes, Bytes.alloc (0));
		#else
		var data:Dynamic = NativeCFFI.lime_gzip_decompress (bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		#end
		
		#elseif (js && html5)
		
		var data = untyped __js__ ("pako.ungzip") (bytes.getData ());
		return Bytes.ofData (data);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
}