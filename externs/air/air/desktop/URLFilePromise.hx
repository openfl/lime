package air.desktop;

extern class URLFilePromise extends flash.events.EventDispatcher implements flash.desktop.IFilePromise
{
	var isAsync(default, never):Bool;
	var relativePath:String;
	var request:flash.net.URLRequest;
	function new():Void;
	function close():Void;
	function open():flash.utils.IDataInput;
	function reportError(e:flash.events.ErrorEvent):Void;
}
