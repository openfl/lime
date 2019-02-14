package air.update.events;

extern class StatusUpdateErrorEvent extends flash.events.ErrorEvent
{
	var subErrorID:Int;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "", id:Int = 0, subErrorID:Int = 0):Void;
	static var UPDATE_ERROR(default, never):String;
}
