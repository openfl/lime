package lime.utils.compress;


import haxe.io.Bytes;

#if !macro
@:build(lime.system.CFFI.build())
#end


class Deflate {
	
	
	public static function compress (bytes:Bytes):Bytes {
		
		#if ((cpp || neko || nodejs) && !macro)
		var data:Dynamic = lime_deflate_compress (bytes);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		#else
		return null;
		#end
		
	}
	
	
	public static function decompress (bytes:Bytes):Bytes {
		
		#if ((cpp || neko || nodejs) && !macro)
		var data:Dynamic = lime_deflate_decompress (bytes);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		#else
		return null;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
	@:cffi private static function lime_deflate_compress (data:Dynamic):Dynamic;
	@:cffi private static function lime_deflate_decompress (data:Dynamic):Dynamic;
	#end
	
	
}