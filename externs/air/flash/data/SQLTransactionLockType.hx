package flash.data;

@:fakeEnum(String) extern enum SQLTransactionLockType
{
	DEFERRED;
	EXCLUSIVE;
	IMMEDIATE;
}
