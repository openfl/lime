package lime.utils.compress;


import haxe.io.Bytes;

#if flash
import flash.utils.ByteArray;
#end

#if !macro
@:build(lime.system.CFFI.build())
#end


class Zlib {
	
	
	public static function compress (bytes:Bytes):Bytes {
		
		#if (lime_cffi && !macro)
		
		#if !cs
		return lime_zlib_compress (bytes, Bytes.alloc (0));
		#else
		var data:Dynamic = lime_zlib_compress (bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		#end
		
		#elseif (js && html5)
		
		var data = untyped __js__ ("pako.deflate") (bytes.getData ());
		return Bytes.ofData (data);
		
		#elseif flash
		
		var byteArray:ByteArray = cast bytes.getData ();
		
		var data = new ByteArray ();
		data.writeBytes (byteArray);
		data.compress ();
		
		return Bytes.ofData (data);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public static function decompress (bytes:Bytes):Bytes {
		
		#if (lime_cffi && !macro)
		
		#if !cs
		return lime_zlib_decompress (bytes, Bytes.alloc (0));
		#else
		var data:Dynamic = lime_zlib_decompress (bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		#end
		
		#elseif (js && html5)
		
		var data = untyped __js__ ("pako.inflate") (bytes.getData ());
		return Bytes.ofData (data);
		
		#elseif flash
		
		var byteArray:ByteArray = cast bytes.getData ();
		
		var data = new ByteArray ();
		data.writeBytes (byteArray);
		data.uncompress ();
		
		return Bytes.ofData (data);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (lime_cffi && !macro)
	@:cffi private static function lime_zlib_compress (data:Dynamic, bytes:Dynamic):Dynamic;
	@:cffi private static function lime_zlib_decompress (data:Dynamic, bytes:Dynamic):Dynamic;
	#end
	
	
}