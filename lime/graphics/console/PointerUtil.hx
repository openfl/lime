package lime.graphics.console; #if lime_console


import cpp.Float32;
import cpp.Pointer;
import lime.math.Matrix4;
import lime.utils.Float32Array;


class PointerUtil {

	public static inline function fromMatrix (m:Matrix4):Pointer<Float32> {

		var array:Float32Array = m;
		var bytePtr = Pointer.arrayElem (array.buffer.getData (), 0);
		return untyped __cpp__ ("(float *){0}", bytePtr.raw);

	}
	
}


#else


class PointerUtil {

	public static function fromMatrix (m:Matrix4):Int { return 0; }

}


#end

