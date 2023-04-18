package flash.media;

@:final extern class StageWebView extends flash.events.EventDispatcher
{
	var isHistoryBackEnabled(default, never):Bool;
	var isHistoryForwardEnabled(default, never):Bool;
	var location(default, never):String;
	var mediaPlaybackRequiresUserAction:Bool;
	var stage:flash.display.Stage;
	var title(default, never):String;
	var viewPort:flash.geom.Rectangle;
	function new():Void;
	function assignFocus(direction:flash.display.FocusDirection = flash.display.FocusDirection.NONE):Void;
	function dispose():Void;
	function drawViewPortToBitmapData(bitmap:flash.display.BitmapData):Void;
	function historyBack():Void;
	function historyForward():Void;
	function loadString(text:String, ?mimeType:String):Void;
	function loadURL(url:String):Void;
	function reload():Void;
	function stop():Void;
	static var isSupported(default, never):Bool;
}
