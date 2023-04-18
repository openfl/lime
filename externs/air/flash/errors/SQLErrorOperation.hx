package flash.errors;

@:native("flash.errors.SQLErrorOperation")
@:enum extern abstract SQLErrorOperation(String)
{
	var ANALYZE;
	var ATTACH;
	var BEGIN;
	var CLOSE;
	var COMMIT;
	var COMPACT;
	var DEANALYZE;
	var DETACH;
	var EXECUTE;
	var OPEN;
	var REENCRYPT;
	var RELEASE_SAVEPOINT;
	var ROLLBACK;
	var ROLLBACK_TO_SAVEPOINT;
	var SCHEMA;
	var SET_SAVEPOINT;
}
