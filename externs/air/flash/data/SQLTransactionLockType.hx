package flash.data;

@:native("flash.data.SQLTransactionLockType")
@:enum extern abstract SQLTransactionLockType(String)
{
	var DEFERRED;
	var EXCLUSIVE;
	var IMMEDIATE;
}
