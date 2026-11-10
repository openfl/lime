package lime._internal.backend.html5;

import lime.net.LocalServer;
import lime.net.LocalSocketError;

class HTML5LocalServer
{
	public var listening(default, null):Bool = false;

	public function new(parent:LocalServer) {}

	public function close():Void {}

	public static function isSupported():Bool
	{
		return false;
	}

	public function listen(name:String):LocalSocketError
	{
		return FAILED;
	}
}
