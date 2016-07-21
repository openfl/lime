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
		#elseif (js && html5)
		var deflate = untyped __js__ ("new Zlib.RawDeflate") (bytes.getData ());
		return Bytes.ofData (deflate.compress ());
		#else
		return null;
		#end
		
	}
	
	
	public static function decompress (bytes:Bytes):Bytes {
		
		#if ((cpp || neko || nodejs) && !macro)
		var data:Dynamic = lime_deflate_decompress (bytes);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		#elseif (js && html5)
		var inflate = untyped __js__ ("new Zlib.RawInflate") (bytes.getData ());
		return Bytes.ofData (inflate.decompress ());
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