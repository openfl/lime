package lime.net;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class HTTPRequestHeader
{
	public var name:String;
	public var value:String;

	public function new(name:String, value:String = "")
	{
		this.name = name;
		this.value = value;
	}
}
