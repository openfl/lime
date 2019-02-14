package flash.net.dns;

extern class MXRecord extends ResourceRecord
{
	var exchange:String;
	var preference:Int;
	function new():Void;
}
