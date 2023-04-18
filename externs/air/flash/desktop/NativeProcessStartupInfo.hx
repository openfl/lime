package flash.desktop;

extern class NativeProcessStartupInfo
{
	var arguments:flash.Vector<String>;
	var executable:flash.filesystem.File;
	var workingDirectory:flash.filesystem.File;
	function new():Void;
}
