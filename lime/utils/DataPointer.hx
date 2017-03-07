package lime.utils;


import haxe.io.BytesData;
import haxe.io.Bytes;
import lime.system.CFFIPointer;
import lime.utils.Bytes in LimeBytes;

#if (lime_cffi && !macro)
import lime._backend.native.NativeCFFI;
@:access(lime._backend.native.NativeCFFI)
#end


abstract DataPointer(DataPointerType) to DataPointerType {
	
	
	private function new (data:DataPointerType) {
		
		this = data;
		
	}
	
	
	@:from @:noCompletion private static function fromInt (value:Int):DataPointer {
		
		#if (lime_cffi && !macro)
		var float:Float = value;
		return new DataPointer (float);
		#elseif (js && !display)
		return new DataPointer (value);
		#else
		return null;
		#end
		
	}
	
	
	@:from @:noCompletion private static function fromFloat (value:Float):DataPointer {
		
		#if (lime_cffi && !macro)
		return new DataPointer (value);
		#elseif (js && !display)
		return new DataPointer (value);
		#else
		return null;
		#end
		
	}
	
	
	@:from @:noCompletion public static function fromBytesPointer (pointer:BytePointer):DataPointer {
		
		#if (lime_cffi && !macro)
		if (pointer == null) return cast 0;
		var data:Float = NativeCFFI.lime_bytes_get_data_pointer (pointer.bytes);
		return new DataPointer (data + pointer.offset);
		#elseif (js && !display)
		return fromBytes (pointer.bytes);
		#else
		return null;
		#end
		
	}
	
	
	@:from @:noCompletion public static function fromArrayBufferView (arrayBufferView:ArrayBufferView):DataPointer {
		
		#if (lime_cffi && !macro)
		if (arrayBufferView == null) return cast 0;
		return fromBytes (arrayBufferView.buffer);
		#elseif (js && !display)
		return new DataPointer (arrayBufferView);
		#else
		return null;
		#end
		
	}
	
	
	@:from @:noCompletion public static function fromArrayBuffer (buffer:ArrayBuffer):DataPointer {
		
		#if (lime_cffi && !macro)
		if (buffer == null) return cast 0;
		return fromBytes (buffer);
		#elseif (js && !display)
		return new DataPointer (buffer);
		#else
		return null;
		#end
		
	}
	
	
	@:from @:noCompletion public static function fromBytes (bytes:Bytes):DataPointer {
		
		#if (lime_cffi && !macro)
		if (bytes == null) return cast 0;
		var data:Float = NativeCFFI.lime_bytes_get_data_pointer (bytes);
		return new DataPointer (data);
		#elseif (js && !display)
		return fromArrayBuffer (bytes.getData ());
		#else
		return null;
		#end
		
	}
	
	
	@:from @:noCompletion public static function fromBytesData (bytesData:BytesData):DataPointer {
		
		#if (lime_cffi && !macro)
		if (bytesData == null) return cast 0;
		return fromBytes (Bytes.ofData (bytesData));
		#elseif (js && !display)
		return fromArrayBuffer (bytesData);
		#else
		return null;
		#end
		
	}
	
	
	@:from @:noCompletion public static function fromLimeBytes (bytes:LimeBytes):DataPointer {
		
		return fromBytes (bytes);
		
	}
	
	
	@:from @:noCompletion public static function fromCFFIPointer (pointer:CFFIPointer):DataPointer {
		
		#if (lime_cffi && !macro)
		if (pointer == null) return cast 0;
		return new DataPointer (pointer.get ());
		#else
		return null;
		#end
		
	}
	
	
	public static function fromFile (path:String):DataPointer {
		
		#if (lime_cffi && !macro)
		return fromBytes (LimeBytes.fromFile (path));
		#else
		return null;
		#end
		
	}
	
	
}


#if (lime_cffi && !js)
private typedef DataPointerType = Float;
#else
private typedef DataPointerType = Dynamic;
#end