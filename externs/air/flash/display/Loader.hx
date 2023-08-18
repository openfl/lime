package flash.display;

extern class Loader extends DisplayObjectContainer
{
	#if (haxe_ver < 4.3)
	var content(default, never):DisplayObject;
	var contentLoaderInfo(default, never):LoaderInfo;
	@:require(flash10_1) var uncaughtErrorEvents(default, never):flash.events.UncaughtErrorEvents;
	#else
	@:flash.property var content(get, never):DisplayObject;
	@:flash.property var contentLoaderInfo(get, never):LoaderInfo;
	@:flash.property @:require(flash10_1) var uncaughtErrorEvents(get, never):flash.events.UncaughtErrorEvents;
	#end
	function new():Void;
	function close():Void;
	function load(request:flash.net.URLRequest, ?context:flash.system.LoaderContext):Void;
	function loadBytes(bytes:flash.utils.ByteArray, ?context:flash.system.LoaderContext):Void;
	#if air
	function loadFilePromise(promise:flash.desktop.IFilePromise, ?context:flash.system.LoaderContext):Void;
	#end
	function unload():Void;
	@:require(flash10) function unloadAndStop(gc:Bool = true):Void;

	#if (haxe_ver >= 4.3)
	private function get_content():DisplayObject;
	private function get_contentLoaderInfo():LoaderInfo;
	private function get_uncaughtErrorEvents():flash.events.UncaughtErrorEvents;
	#end
}
