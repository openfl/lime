package flash.html;

extern class HTMLHistoryItem
{
	var isPost(default, never):Bool;
	var originalUrl(default, never):String;
	var title(default, never):String;
	var url(default, never):String;
	function new(url:String, originalUrl:String, isPost:Bool, title:String):Void;
}
