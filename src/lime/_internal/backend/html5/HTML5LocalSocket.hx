package lime._internal.backend.html5;

import lime.net.LocalSocket;
import lime.utils.Bytes;

class HTML5LocalSocket
{
	public var connected(default, null):Bool = false;
	public var maxQueuedBytes(default, null):Int = 0;

	public function new(parent:LocalSocket) {}

	public function close():Void {}

	public function connect(name:String, timeout:Int):Void {}

	public function getBytesPending():Int
	{
		return 0;
	}

	public static function isSupported():Bool
	{
		return false;
	}

	public function send(data:Bytes, offset:Int, length:Int):Bool
	{
		return false;
	}

	public function setMaxQueuedBytes(value:Int):Void
	{
		maxQueuedBytes = value;
	}
}
