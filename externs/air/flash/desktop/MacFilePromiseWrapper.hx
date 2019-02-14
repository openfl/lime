package flash.desktop;

extern class MacFilePromiseWrapper extends flash.events.EventDispatcher
{
	function new(promise:IFilePromise, dropDirectory:flash.filesystem.File):Void;
	function open():Bool;
}
