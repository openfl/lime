package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class CairoGlyph
{
	public var index:Int;
	public var x:Float;
	public var y:Float;

	public function new(index:Int, x:Float = 0, y:Float = 0)
	{
		this.index = index;
		this.x = x;
		this.y = y;
	}
}
#end
