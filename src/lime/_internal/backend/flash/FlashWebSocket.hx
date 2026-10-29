package lime._internal.backend.flash;

import lime.net.WebSocket;
import lime.utils.Bytes;

class FlashWebSocket
{
	public function new(parent:WebSocket) {}

	public function close(code:Int, reason:String):Void {}

	public function connect(url:String, protocols:Array<String>, timeout:Int):Void {}

	public function getBytesPending():Int
	{
		return 0;
	}

	public function getExtensions():String
	{
		return "";
	}

	public function getIdleTimeout():Int
	{
		return 0;
	}

	public function getMaxMessageSize():Int
	{
		return 0;
	}

	public function getMaxQueuedBytes():Int
	{
		return 0;
	}

	public function getPingInterval():Int
	{
		return 0;
	}

	public function getProtocol():String
	{
		return null;
	}

	public function getRemoteAddress():String
	{
		return null;
	}

	public function getRemotePort():Int
	{
		return 0;
	}

	public function isConnected():Bool
	{
		return false;
	}

	public static function isSupported():Bool
	{
		return false;
	}

	public function ping(data:Bytes):Void {}

	public function send(data:Bytes, offset:Int, length:Int):Bool
	{
		return false;
	}

	public function sendText(text:String):Bool
	{
		return false;
	}

	public function setIdleTimeout(value:Int):Void {}

	public function setMaxMessageSize(value:Int):Void {}

	public function setMaxQueuedBytes(value:Int):Void {}

	public function setPingInterval(value:Int):Void {}
}
