package flash.events;

extern class SQLEvent extends Event
{
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false):Void;
	static var ANALYZE(default, never):String;
	static var ATTACH(default, never):String;
	static var BEGIN(default, never):String;
	static var CANCEL(default, never):String;
	static var CLOSE(default, never):String;
	static var COMMIT(default, never):String;
	static var COMPACT(default, never):String;
	static var DEANALYZE(default, never):String;
	static var DETACH(default, never):String;
	static var OPEN(default, never):String;
	static var REENCRYPT(default, never):String;
	static var RELEASE_SAVEPOINT(default, never):String;
	static var RESULT(default, never):String;
	static var ROLLBACK(default, never):String;
	static var ROLLBACK_TO_SAVEPOINT(default, never):String;
	static var SCHEMA(default, never):String;
	static var SET_SAVEPOINT(default, never):String;
}
