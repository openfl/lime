package lime.text;

import lime.math.Vector2;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class GlyphMetrics
{
	public var advance:Vector2;
	public var height:Int;
	public var horizontalBearing:Vector2;
	public var verticalBearing:Vector2;

	public function new() {}
}
