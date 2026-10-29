package lime._internal.backend.html5;

import haxe.Timer;
import js.html.CloseEvent;
import js.html.MessageEvent;
import js.html.WebSocket as BrowserWebSocket;
import js.lib.ArrayBuffer;
import lime.net.WebSocket;
import lime.net.WebSocketError;
import lime.utils.Bytes;

/**
	A WebSocket's side in a browser: the page's own `WebSocket`, which frames
	the protocol itself.
**/
@:access(lime.net.WebSocket)
class HTML5WebSocket
{
	private var maxQueuedBytes:Int = WebSocket.DEFAULT_MAX_QUEUED_BYTES;
	private var parent:WebSocket;
	private var socket:BrowserWebSocket;
	private var timeout:Timer;

	public function new(parent:WebSocket)
	{
		this.parent = parent;
	}

	public function close(code:Int, reason:String):Void
	{
		if (socket == null) return;

		try
		{
			// A browser takes 1000 and 3000 to 4999 from a page, and no other
			socket.close(code == 1000 || (code >= 3000 && code <= 4999) ? code : 1000, reason != null ? reason : "");
		}
		catch (_:Dynamic)
		{
			socket.close();
		}
	}

	public function connect(url:String, protocols:Array<String>, timeout:Int):Void
	{
		release();

		var socket:BrowserWebSocket;
		try
		{
			socket = protocols != null && protocols.length > 0 ? new BrowserWebSocket(url, protocols) : new BrowserWebSocket(url);
		}
		catch (e:Dynamic)
		{
			parent.onError.dispatch(WebSocketError.CONNECT_FAILED, "Could not connect to " + url + ": " + e);
			parent.onClose.dispatch(1006, "");
			return;
		}

		this.socket = socket;
		// Whether it opened, or failed and said so: a browser follows a failed
		// connection's close with an error of its own
		var settled = false;

		socket.binaryType = ARRAYBUFFER;
		socket.onopen = function(_)
		{
			settled = true;
			stopTimeout();
			parent.onConnect.dispatch();
		};
		socket.onmessage = function(event:MessageEvent)
		{
			if (Std.isOfType(event.data, String))
			{
				parent.onText.dispatch(event.data);
			}
			else
			{
				parent.onData.dispatch(Bytes.ofData(cast(event.data, ArrayBuffer)));
			}
		};
		socket.onerror = function(_)
		{
			// A browser says no more than that something failed. Once open, a
			// failure is reported as native targets report it, by onClose's 1006
			if (settled) return;
			settled = true;
			parent.onError.dispatch(WebSocketError.CONNECT_FAILED, "The WebSocket connection to " + url + " failed");
		};
		socket.onclose = function(event:CloseEvent)
		{
			stopTimeout();
			parent.onClose.dispatch(event.code, event.reason);
		};

		if (timeout > 0)
		{
			this.timeout = Timer.delay(function()
			{
				this.timeout = null;
				if (this.socket == socket && socket.readyState == BrowserWebSocket.CONNECTING)
				{
					settled = true;
					parent.onError.dispatch(WebSocketError.TIMEOUT, "Failed to connect to server: " + url + " did not open in time");
					socket.close();
				}
			}, timeout);
		}
	}

	public function getBytesPending():Int
	{
		return socket != null ? socket.bufferedAmount : 0;
	}

	public function getExtensions():String
	{
		return socket != null ? socket.extensions : "";
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
		return maxQueuedBytes;
	}

	public function getPingInterval():Int
	{
		return 0;
	}

	public function getProtocol():String
	{
		return socket != null && socket.protocol != "" ? socket.protocol : null;
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
		return socket != null && socket.readyState == BrowserWebSocket.OPEN;
	}

	public static function isSupported():Bool
	{
		return js.Syntax.code("typeof WebSocket !== 'undefined'");
	}

	public function ping(data:Bytes):Void {}

	public function send(data:Bytes, offset:Int, length:Int):Bool
	{
		if (!isConnected()) return false;
		socket.send(data.getData().slice(offset, offset + length));
		return !overflowed();
	}

	public function sendText(text:String):Bool
	{
		if (!isConnected()) return false;
		socket.send(text);
		return !overflowed();
	}

	public function setIdleTimeout(value:Int):Void {}

	public function setMaxMessageSize(value:Int):Void {}

	public function setMaxQueuedBytes(value:Int):Void
	{
		maxQueuedBytes = value;
	}

	public function setPingInterval(value:Int):Void {}

	// The limit, after a send: true when it closed the connection, as native
	// targets close it
	private function overflowed():Bool
	{
		var waiting = socket.bufferedAmount;
		if (maxQueuedBytes <= 0 || waiting <= maxQueuedBytes) return false;

		release();
		parent.onError.dispatch(WebSocketError.OVERFLOW, waiting + " bytes waited to be sent, past maxQueuedBytes (" + maxQueuedBytes
			+ "); the peer is not reading");
		parent.onClose.dispatch(1011, "output buffer limit exceeded");
		return true;
	}

	// The connection there was, let go of without events
	private function release():Void
	{
		stopTimeout();
		if (socket == null) return;

		var socket = this.socket;
		this.socket = null;
		socket.onopen = null;
		socket.onmessage = null;
		socket.onerror = null;
		socket.onclose = null;

		try
		{
			socket.close();
		}
		catch (_:Dynamic) {}
	}

	private function stopTimeout():Void
	{
		if (timeout != null)
		{
			timeout.stop();
			timeout = null;
		}
	}
}
