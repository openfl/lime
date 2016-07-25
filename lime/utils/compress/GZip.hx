package lime.utils.compress;


import haxe.io.Bytes;

#if !macro
@:build(lime.system.CFFI.build())
#end


class GZip {
	
	
	public static function compress (bytes:Bytes):Bytes {
		
		#if ((cpp || neko || nodejs) && !macro)
		
		var data:Dynamic = lime_gzip_compress (bytes);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		
		#elseif (js && html5)
		
		var data = untyped __js__ ("pako.gzip") (bytes.getData ());
		return Bytes.ofData (data);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public static function decompress (bytes:Bytes):Bytes {
		
		#if ((cpp || neko || nodejs) && !macro)
		
		var data:Dynamic = lime_gzip_decompress (bytes);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		
		#elseif (js && html5)
		
		var data = untyped __js__ ("pako.ungzip") (bytes.getData ());
		return Bytes.ofData (data);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
	@:cffi private static function lime_gzip_compress (data:Dynamic):Dynamic;
	@:cffi private static function lime_gzip_decompress (data:Dynamic):Dynamic;
	#end
	
	
}