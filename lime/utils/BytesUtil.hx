package lime.utils;

import haxe.io.Bytes;

class BytesUtil
{

	public static function getAnonBytesFromByteArray (byteArray:ByteArray):AnonBytes {
		
		#if js
		var u8a:UInt8Array = cast byteArray.b;
		return {length:u8a.byteLength, b:u8a};
		#else
		return cast byteArray;
		#end
		
	}
	
	public static function getAnonBytesFromTypedArray (array:ArrayBufferView):AnonBytes {
		
		#if js
		return {length:array.byteLength, b:array};
		#else
		return cast array;
		#end
		
	}
	
	public static function getBytesFromByteArray (byteArray:ByteArray):Bytes {
		
		#if js
		var u8a:UInt8Array = cast byteArray.b;
		return u8a.toBytes ();
		#else
		return byteArray;
		#end
		
	}

	public static function getUInt8ArrayFromByteArray (byteArray:ByteArray):UInt8Array {
		
		#if js
		return byteArray.b;
		#elseif flash
		var u8a:UInt8Array = new UInt8Array (byteArray.length);
		u8a.buffer.getData ().readBytes (byteArray);
		return u8a;
		#else
		return new UInt8Array (byteArray);
		#end
		
	}
	
	public static function getUInt8ArrayFromAnonBytes (ab:AnonBytes):UInt8Array {
		
		#if js
		return ab.b;
		#else
		return new UInt8Array (@:privateAccess new Bytes (ab.length, ab.b));
		#end
		
	}
	
	public static function createBytes (length:Int, b:Dynamic):Bytes {
		
		#if ((js && haxe < 3.2) || !js)
		@:privateAccess return new Bytes (length, b);
		#else
		@:privateAccess return new Bytes (b);
		#end
		
	}
	
}