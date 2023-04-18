package air.update.events;

extern class DownloadErrorEvent extends flash.events.ErrorEvent
{
	var subErrorID:Int;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "", id:Int = 0, subErrorID:Int = 0):Void;
	static var DOWNLOAD_ERROR(default, never):String;
}
