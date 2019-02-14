package flash.security;

extern class AVMPlusDigest
{
	function new():Void;
	function FinishDigest(inDigestToCompare:String):UInt;
	function Init(algorithm:UInt):Void;
	function Update(data:flash.utils.IDataInput):UInt;
	function UpdateWithString(data:String):UInt;
	static var DIGESTMETHOD_SHA256(default, never):UInt;
}
