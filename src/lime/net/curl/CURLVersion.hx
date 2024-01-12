package lime.net.curl;

#if (!lime_doc_gen || lime_curl)
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract CURLVersion(Int) from Int to Int from UInt to UInt
{
	var FIRST = 0;
	var SECOND = 1;
	var THIRD = 2;
	var FOURTH = 3;
	// var LAST = 4;
}
#end
