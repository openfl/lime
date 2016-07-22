package lime.utils.compress;


import haxe.io.Bytes;

#if flash
import flash.utils.CompressionAlgorithm;
import flash.utils.ByteArray;
#end

#if !macro
@:build(lime.system.CFFI.build())
#end


class LZMA {
	
	
	public static function compress (bytes:Bytes):Bytes {
		
		#if ((cpp || neko || nodejs) && !macro)
		
		var data:Dynamic = lime_lzma_compress (bytes);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		
		#elseif flash
		
		var byteArray:ByteArray = cast bytes.getData ();
		
		var data = new ByteArray ();
		data.writeBytes (byteArray);
		data.compress (CompressionAlgorithm.LZMA);
		
		return Bytes.ofData (data);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public static function decompress (bytes:Bytes):Bytes {
		
		#if ((cpp || neko || nodejs) && !macro)
		
		var data:Dynamic = lime_lzma_decompress (bytes);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		
		#elseif flash
		
		var byteArray:ByteArray = cast bytes.getData ();
		
		var data = new ByteArray ();
		data.writeBytes (byteArray);
		data.uncompress (CompressionAlgorithm.LZMA);
		
		return Bytes.ofData (data);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
	@:cffi private static function lime_lzma_compress (data:Dynamic):Dynamic;
	@:cffi private static function lime_lzma_decompress (data:Dynamic):Dynamic;
	#end
	
	
}