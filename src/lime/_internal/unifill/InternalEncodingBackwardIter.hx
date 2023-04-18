package lime._internal.unifill;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class InternalEncodingBackwardIter
{
	public var string:String;
	public var beginIndex:Int;
	public var index:Int;

	public inline function new(s:String, beginIndex:Int, endIndex:Int)
	{
		string = s;
		this.beginIndex = beginIndex;
		this.index = endIndex;
	}

	public inline function hasNext():Bool
	{
		return beginIndex < index;
	}

	public inline function next():Int
	{
		index -= InternalEncoding.codePointWidthBefore(string, index);
		return index;
	}
}
