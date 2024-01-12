package flash.data;

@:native("flash.data.SQLTransactionLockType")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract SQLTransactionLockType(String)
{
	var DEFERRED = "deferred";
	var EXCLUSIVE = "exclusive";
	var IMMEDIATE = "immediate";
}
