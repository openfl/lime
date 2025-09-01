package flash.display;

extern class Screen extends flash.events.EventDispatcher
{
	#if (haxe_ver < 4.3)
	var bounds(default, never):flash.geom.Rectangle;
	var colorDepth(default, never):Int;
	var visibleBounds(default, never):flash.geom.Rectangle;
	static var mainScreen(default, never):Screen;
	static var screens(default, never):Array<Screen>;
	#else
	@:flash.property var bounds(get, never):flash.geom.Rectangle;
	@:flash.property var colorDepth(get, never):Int;
	@:flash.property var visibleBounds(get, never):flash.geom.Rectangle;
	@:flash.property static var mainScreen(get, never):Screen;
	@:flash.property static var screens(get, never):Array<Screen>;
	#end
	function new():Void;
	static function getScreensForRectangle(rect:flash.geom.Rectangle):Array<Screen>;

	#if (haxe_ver >= 4.3)
	private function get_bounds():flash.geom.Rectangle;
	private function get_colorDepth():Int;
	private function get_visibleBounds():flash.geom.Rectangle;
	private static function get_mainScreen():Screen;
	private static function get_screens():Array<Screen>;
	#end
}
