package flash.html;

extern class HTMLLoader extends flash.display.Sprite
{
	var authenticate:Bool;
	var cacheResponse:Bool;
	var contentHeight(default, never):Float;
	var contentWidth(default, never):Float;
	var hasFocusableContent(default, never):Bool;
	var historyLength(default, never):UInt;
	var historyPosition:UInt;
	var htmlHost:HTMLHost;
	var idleTimeout:Float;
	var loaded(default, never):Bool;
	var location(default, never):String;
	var manageCookies:Bool;
	var navigateInSystemBrowser:Bool;
	var pageApplicationDomain(default, never):flash.system.ApplicationDomain;
	var paintsDefaultBackground:Bool;
	var placeLoadStringContentInApplicationSandbox:Bool;
	var runtimeApplicationDomain:flash.system.ApplicationDomain;
	var scrollH:Float;
	var scrollV:Float;
	var textEncodingFallback:String;
	var textEncodingOverride:String;
	var useCache:Bool;
	var userAgent:String;
	var window(default, never):Dynamic;
	function new():Void;
	function cancelLoad():Void;
	function getHistoryAt(position:UInt):HTMLHistoryItem;
	function historyBack():Void;
	function historyForward():Void;
	function historyGo(steps:Int):Void;
	function load(urlRequestToLoad:flash.net.URLRequest):Void;
	function loadString(htmlContent:String):Void;
	function reload():Void;
	static var isSupported(default, never):Bool;
	static var pdfCapability(default, never):Int;
	static var swfCapability(default, never):Int;
	static function createRootWindow(visible:Bool = true, ?windowInitOptions:flash.display.NativeWindowInitOptions, scrollBarsVisible:Bool = true,
		?bounds:flash.geom.Rectangle):HTMLLoader;
}
