package lime._internal.unifill;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class InternalEncodingIter
{
	public var string:String;
	public var index:Int;
	public var endIndex:Int;

	public inline function new(s:String, beginIndex:Int, endIndex:Int)
	{
		string = s;
		this.index = beginIndex;
		this.endIndex = endIndex;
	}

	public inline function hasNext():Bool
	{
		return index < endIndex;
	}

	var i = 0; // FIXME: blocked by HaxeFoundation/haxe#4353

	public inline function next():Int
	{
		i = index;
		index += InternalEncoding.codePointWidthAt(string, index);
		return i;
	}
}
