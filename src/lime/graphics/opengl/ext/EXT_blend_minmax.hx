package lime.graphics.opengl.ext;


@:keep


#if (!js || !html5 || display)


class EXT_blend_minmax {
	
	
	public var MIN_EXT = 0x8007;
	public var MAX_EXT = 0x8008;
	
	
	private function new () {
		
		
		
	}
	
	
}


#else


@:native("ANGLE_instanced_arrays")
extern class EXT_blend_minmax {
	
	
	public var MIN_EXT:Int;
	public var MAX_EXT:Int;
	
	
}


#end