package lime.utils.compress;


import haxe.io.Bytes;

#if !macro
@:build(lime.system.CFFI.build())
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GZip {
	
	
	public static function compress (bytes:Bytes):Bytes {
		
		#if (lime_cffi && !macro)
		
		#if !cs
		return lime_gzip_compress (bytes, Bytes.alloc (0));
		#else
		var data:Dynamic = lime_gzip_compress (bytes, null);
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
		return lime_gzip_decompress (bytes, Bytes.alloc (0));
		#else
		var data:Dynamic = lime_gzip_decompress (bytes, null);
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
	
	
	
	
	// Native Methods
	
	
	
	
	#if (lime_cffi && !macro)
	@:cffi private static function lime_gzip_compress (data:Dynamic, bytes:Dynamic):Dynamic;
	@:cffi private static function lime_gzip_decompress (data:Dynamic, bytes:Dynamic):Dynamic;
	#end
	
	
}