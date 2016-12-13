package lime.utils;


import haxe.io.Bytes in HaxeBytes;
import haxe.io.BytesData;
import lime.app.Future;
import lime.net.HTTPRequest;

#if !macro
@:build(lime.system.CFFI.build())
#end

@:access(haxe.io.Bytes)
@:forward()


abstract Bytes(HaxeBytes) from HaxeBytes to HaxeBytes {
	
	
	public function new (length:Int, bytesData:BytesData) {
		
		#if js
		this = new HaxeBytes (bytesData);
		#else
		this = new HaxeBytes (length, bytesData);
		#end
		
	}
	
	
	public static function alloc (length:Int):Bytes {
		
		var bytes = HaxeBytes.alloc (length);
		return new Bytes (bytes.length, bytes.getData ());
		
	}
	
	
	public static inline function fastGet (b:BytesData, pos:Int):Int {
		
		return HaxeBytes.fastGet (b, pos);
		
	}
	
	
	public static function fromBytes (bytes:haxe.io.Bytes):Bytes {
		
		return new Bytes (bytes.length, bytes.getData ());
		
	}
	
	
	public static function fromFile (path:String):Bytes {
		
		#if (!html5 && !macro)
		var data:Dynamic = lime_bytes_read_file (path);
		if (data != null) return new Bytes (data.length, data.b);
		#end
		return null;
		
	}
	
	
	public static function loadFromBytes (bytes:haxe.io.Bytes):Future<Bytes> {
		
		return Future.withValue (fromBytes (bytes));
		
	}
	
	
	public static function loadFromFile (path:String):Future<Bytes> {
		
		var request = new HTTPRequest<Bytes> ();
		return request.load (path);
		
	}
	
	
	public static function ofData (b:BytesData):Bytes {
		
		var bytes = HaxeBytes.ofData (b);
		return new Bytes (bytes.length, bytes.getData ());
		
	}
	
	
	public static function ofString (s:String):Bytes {
		
		var bytes = HaxeBytes.ofString (s);
		return new Bytes (bytes.length, bytes.getData ());
		
	}
	
	
	#if (lime_cffi && !macro)
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