package air.update.events;

extern class StatusFileUpdateErrorEvent extends flash.events.ErrorEvent
{
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "", id:Int = 0):Void;
	static var FILE_UPDATE_ERROR(default, never):String;
}
