package lime.utils.compress;


import haxe.io.Bytes;

#if !macro
@:build(lime.system.CFFI.build())
#end


class Zlib {
	
	
	public static function compress (bytes:Bytes):Bytes {
		
		#if ((cpp || neko || nodejs) && !macro)
		var data:Dynamic = lime_zlib_compress (bytes);
		return @:privateAccess new Bytes (data.length, data.b);
		#else
		return null;
		#end
		
	}
	
	
	public static function decompress (bytes:Bytes):Bytes {
		
		#if ((cpp || neko || nodejs) && !macro)
		var data:Dynamic = lime_zlib_decompress (bytes);
		return @:privateAccess new Bytes (data.length, data.b);
		#else
		return null;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
	@:cffi private static function lime_zlib_compress (data:Dynamic):Dynamic;
	@:cffi private static function lime_zlib_decompress (data:Dynamic):Dynamic;
	#end
	
	
}