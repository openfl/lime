package lime._internal.backend.flash;

import lime.net.WebSocketError;
import lime.net.WebSocketServer;

class FlashWebSocketServer
{
	public var listening(default, null):Bool = false;

	private var protocols:Array<String> = null;

	public function new(parent:WebSocketServer) {}

	public function close():Void {}

	public function getLocalPort():Int
	{
		return 0;
	}

	public function getProtocols():Array<String>
	{
		return protocols;
	}

	public static function isSupported():Bool
	{
		return false;
	}

	public function listen(port:Int, host:String, backlog:Int):WebSocketError
	{
		return WebSocketError.LISTEN_FAILED;
	}

	public function setProtocols(value:Array<String>):Void
	{
		protocols = value;
	}
}
