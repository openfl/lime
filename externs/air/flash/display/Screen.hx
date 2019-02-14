package flash.display;

extern class Screen extends flash.events.EventDispatcher
{
	var bounds(default, never):flash.geom.Rectangle;
	var colorDepth(default, never):Int;
	var visibleBounds(default, never):flash.geom.Rectangle;
	function new():Void;
	static var mainScreen(default, never):Screen;
	static var screens(default, never):Array<Screen>;
	static function getScreensForRectangle(rect:flash.geom.Rectangle):Array<Screen>;
}
