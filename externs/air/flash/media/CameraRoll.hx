package flash.media;

extern class CameraRoll extends flash.events.EventDispatcher
{
	function new():Void;
	function addBitmapData(bitmapData:flash.display.BitmapData):Void;
	function browseForImage(?value:CameraRollBrowseOptions):Void;
	function requestPermission():Void;
	static var permissionStatus(default, never):String;
	static var supportsAddBitmapData(default, never):Bool;
	static var supportsBrowseForImage(default, never):Bool;
}
