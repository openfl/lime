package flash.security;

extern interface IURIDereferencer
{
	function dereference(uri:String):flash.utils.IDataInput;
}
