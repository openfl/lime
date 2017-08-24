package flash.desktop;

extern class FilePromiseManager extends flash.events.EventDispatcher {
	function new() : Void;
	function addPromises(clipboard : Clipboard, dropDirectoryPath : String) : Bool;
	static var DATA_EVENT_TIMEOUT : Int;
	static var FILE_PROMISE_ERR_CLOSE : Int;
	static var FILE_PROMISE_ERR_OPEN : Int;
	static var FILE_PROMISE_ERR_TIMEOUT : Int;
	static function newFilePromiseErrorEvent(code : Int) : flash.events.Event;
}
