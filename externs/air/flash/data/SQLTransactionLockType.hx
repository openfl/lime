package flash.data;

@:native("flash.data.SQLTransactionLockType")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract SQLTransactionLockType(String)
{
	var DEFERRED;
	var EXCLUSIVE;
	var IMMEDIATE;
}
