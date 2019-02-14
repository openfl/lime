package flash.net.dns;

extern class SRVRecord extends ResourceRecord
{
	var port:Int;
	var priority:Int;
	var target:String;
	var weight:Int;
	function new():Void;
}
