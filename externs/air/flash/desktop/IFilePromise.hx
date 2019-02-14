package flash.desktop;

extern interface IFilePromise
{
	var isAsync(default, never):Bool;
	var relativePath(default, never):String;
	function close():Void;
	function open():flash.utils.IDataInput;
	function reportError(e:flash.events.ErrorEvent):Void;
}
