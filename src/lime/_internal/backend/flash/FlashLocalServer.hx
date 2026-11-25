package lime._internal.backend.flash;

import lime.net.LocalServer;
import lime.net.LocalSocketError;

class FlashLocalServer
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
