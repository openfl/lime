package lime.utils;

import haxe.io.Bytes;

@:transitive
abstract Resource(Bytes) from Bytes to Bytes
{
	public function new(size:Int = 0)
	{
		this = Bytes.alloc(size);
	}

	@:from private static inline function __fromString(value:String):Resource
	{
		return Bytes.ofString(value);
	}

	@:to private static inline function __toString(value:Resource):String
	{
		return (value : Bytes).toString();
	}
}
