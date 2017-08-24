package flash.events;

extern class SQLEvent extends Event {
	function new(type : String, bubbles : Bool=false, cancelable : Bool=false) : Void;
	static var ANALYZE : String;
	static var ATTACH : String;
	static var BEGIN : String;
	static var CANCEL : String;
	static var CLOSE : String;
	static var COMMIT : String;
	static var COMPACT : String;
	static var DEANALYZE : String;
	static var DETACH : String;
	static var OPEN : String;
	static var REENCRYPT : String;
	static var RELEASE_SAVEPOINT : String;
	static var RESULT : String;
	static var ROLLBACK : String;
	static var ROLLBACK_TO_SAVEPOINT : String;
	static var SCHEMA : String;
	static var SET_SAVEPOINT : String;
}
