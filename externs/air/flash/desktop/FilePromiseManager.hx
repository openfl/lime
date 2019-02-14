package flash.desktop;

extern class FilePromiseManager extends flash.events.EventDispatcher
{
	function new():Void;
	function addPromises(clipboard:Clipboard, dropDirectoryPath:String):Bool;
	static var ASYNC_FILE_PROMISE_DONE_EVENT(default, never):String;
	static var DATA_EVENT_TIMEOUT(default, never):Int;
	static var FILE_PROMISE_ERR_CLOSE(default, never):Int;
	static var FILE_PROMISE_ERR_OPEN(default, never):Int;
	static var FILE_PROMISE_ERR_TIMEOUT(default, never):Int;
	static function newFilePromiseErrorEvent(code:Int):flash.events.Event;
}
