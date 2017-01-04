package lime.utils.compress;


import haxe.io.Bytes;

#if flash
import flash.utils.CompressionAlgorithm;
import flash.utils.ByteArray;
#end

#if !macro
@:build(lime.system.CFFI.build())
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class LZMA {
	
	
	public static function compress (bytes:Bytes):Bytes {
		
		#if (lime_cffi && !macro)
		
		#if !cs
		return lime_lzma_compress (bytes, Bytes.alloc (0));
		#else
		var data:Dynamic = lime_lzma_compress (bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		#end
		
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
		
		#if (lime_cffi && !macro)
		
		#if !cs
		return lime_lzma_decompress (bytes, Bytes.alloc (0));
		#else
		var data:Dynamic = lime_lzma_decompress (bytes, null);
		if (data == null) return null;
		return @:privateAccess new Bytes (data.length, data.b);
		#end
		
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
	
	
	
	
	#if (lime_cffi && !macro)
	@:cffi private static function lime_lzma_compress (data:Dynamic, bytes:Dynamic):Dynamic;
	@:cffi private static function lime_lzma_decompress (data:Dynamic, bytes:Dynamic):Dynamic;
	#end
	
	
}