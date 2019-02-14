package lime._internal.unifill;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Exception
{
	function new() {}

	public function toString():String
	{
		throw null;
	}
}

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class InvalidCodePoint extends Exception
{
	public var code(default, null):Int;

	public function new(code:Int)
	{
		super();
		this.code = code;
	}

	override public function toString():String
	{
		return 'InvalidCodePoint(code: $code)';
	}
}

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class InvalidCodeUnitSequence extends Exception
{
	public var index(default, null):Int;

	public function new(index:Int)
	{
		super();
		this.index = index;
	}

	override public function toString():String
	{
		return 'InvalidCodeUnitSequence(index: $index)';
	}
}
