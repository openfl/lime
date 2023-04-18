package flash.media;

extern class MediaPromise extends flash.events.EventDispatcher implements flash.desktop.IFilePromise
{
	var file(default, never):flash.filesystem.File;
	var isAsync(default, never):Bool;
	var mediaType(default, never):String;
	var relativePath(default, never):String;
	function new():Void;
	function close():Void;
	function open():flash.utils.IDataInput;
	function reportError(e:flash.events.ErrorEvent):Void;
}
