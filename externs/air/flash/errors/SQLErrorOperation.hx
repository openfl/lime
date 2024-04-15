package flash.errors;

@:native("flash.errors.SQLErrorOperation")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract SQLErrorOperation(String)
{
	var ANALYZE = "analyze";
	var ATTACH = "attach";
	var BEGIN = "begin";
	var CLOSE = "close";
	var COMMIT = "commit";
	var COMPACT = "compact";
	var DEANALYZE = "deanalyze";
	var DETACH = "detach";
	var EXECUTE = "execute";
	var OPEN = "open";
	var REENCRYPT = "reencrypt";
	var RELEASE_SAVEPOINT = "releaseSavepoint";
	var ROLLBACK = "rollback";
	var ROLLBACK_TO_SAVEPOINT = "rollbackToSavepoint";
	var SCHEMA = "schema";
	var SET_SAVEPOINT = "setSavepoint";
}
