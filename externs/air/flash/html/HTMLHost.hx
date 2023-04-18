package flash.html;

extern class HTMLHost
{
	var htmlLoader(default, never):HTMLLoader;
	var windowRect:flash.geom.Rectangle;
	function new(defaultBehaviors:Bool = true):Void;
	function createWindow(windowCreateOptions:HTMLWindowCreateOptions):HTMLLoader;
	// function setHTMLControl(loader : HTMLLoader) : Void;
	function updateLocation(locationURL:String):Void;
	function updateStatus(status:String):Void;
	function updateTitle(title:String):Void;
	function windowBlur():Void;
	function windowClose():Void;
	function windowFocus():Void;
}
