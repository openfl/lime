package lime._internal.backend.html5;

import lime.net.LocalSocket;
import lime.net.LocalSocketError;
import lime.utils.Bytes;

class HTML5LocalSocket
{
	public var connected(default, null):Bool = false;
	public var maxQueuedBytes(default, null):Int = 0;

	private var parent:LocalSocket;

	public function new(parent:LocalSocket)
	{
		this.parent = parent;
	}

	public function close():Void {}

	public function connect(name:String, timeout:Int):Void
	{
		parent.onError.dispatch(LocalSocketError.FAILED);
		parent.onClose.dispatch();
	}

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
