package lime.utils;


import haxe.io.Bytes in HaxeBytes;
import haxe.io.BytesData;

#if !macro
@:build(lime.system.CFFI.build())
#end

@:autoBuild(lime.Assets.embedBytes())


class Bytes extends HaxeBytes {
	
	
	public function new (length:Int, bytesData:BytesData) {
		
		#if js
		super (bytesData);
		#else
		super (length, bytesData);
		#end
		
	}
	
	
	public static function alloc (length:Int):Bytes {
		
		var bytes = HaxeBytes.alloc (length);
		return new Bytes (bytes.length, bytes.getData ());
		
	}
	
	
	public static inline function fastGet (b:BytesData, pos:Int):Int {
		
		return HaxeBytes.fastGet (b, pos);
		
	}
	
	
	public static function ofData (b:BytesData):Bytes {
		
		var bytes = HaxeBytes.ofData (b);
		return new Bytes (bytes.length, bytes.getData ());
		
	}
	
	
	public static function ofString (s:String):Bytes {
		
		var bytes = HaxeBytes.ofString (s);
		return new Bytes (bytes.length, bytes.getData ());
		
	}
	
	
	public static function readFile (path:String):Bytes {
		
		#if (!html5 && !macro)
		var data:Dynamic = lime_bytes_read_file (path);
		if (data != null) return new Bytes (data.length, data.b);
		#end
		return null;
		
	}
	
	
	#if ((cpp || neko || nodejs) && !macro)
	public static function __fromNativePointer (data:Dynamic, length:Int):Bytes {
		
		var bytes:Dynamic = lime_bytes_from_data_pointer (data, length);
		return new Bytes (bytes.length, bytes.b);
		
	}
	#end
	
	
	
	
	// Native Methods
	
	
	
	
	#if !macro
	@:cffi private static function lime_bytes_from_data_pointer (data:Float, length:Int):Dynamic;
	@:cffi private static function lime_bytes_get_data_pointer (data:Dynamic):Float;
	@:cffi private static function lime_bytes_read_file (path:String):Dynamic;
	#end
	
	
}