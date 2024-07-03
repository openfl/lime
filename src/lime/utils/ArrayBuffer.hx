package lime.utils;

#if (js && !doc_gen)
typedef ArrayBuffer = #if haxe4 js.lib.ArrayBuffer #else js.html.ArrayBuffer #end;
#else
import haxe.io.Bytes;

@:forward
@:transitive
abstract ArrayBuffer(Bytes) from Bytes to Bytes
	#if doc_gen from Dynamic to Dynamic
	#end
{
	public var byteLength(get, never):Int;

	private inline function get_byteLength()
	{
		return this.length;
	}

	public inline function new(byteLength:Int)
	{
		this = Bytes.alloc(byteLength);
	}

	public static inline function isView(arg:Dynamic):Bool
	{
		return (arg != null && (arg is ArrayBufferView));
	}

	public inline function slice(begin:Int, end:Null<Int> = null)
	{
		if (end == null) end = this.length;
		if (begin < 0) begin = 0;
		if (end > this.length) end = this.length;
		var length = end - begin;
		if (begin < 0 || length <= 0)
		{
			return new ArrayBuffer(0);
		}
		else
		{
			var bytes = Bytes.alloc(length);
			bytes.blit(0, this, begin, length);
			return cast bytes;
		}
	}
}
#end // !js
