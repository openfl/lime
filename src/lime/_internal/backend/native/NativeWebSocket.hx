package lime._internal.backend.native;

import haxe.io.Bytes;
import lime.net.WebSocket;
import lime.net.WebSocketError;
#if (haxe4 && (cpp || hl || neko))
import wsproto.socket.Connection;
import wsproto.socket.Loop;
#end

/**
	A WebSocket's native side: a `Connection` of wsproto's, the library
	CrossByte's WebSocket runs on, over a socket of Haxe's own, whose
	callbacks become the `WebSocket`'s events.

	Every connection and server is on one loop of Lime's, which the
	application's loop polls once a frame (`__update`) from the first one
	on: what has arrived is read and delivered there, and what waits to go
	is written. A client's connect runs on a thread of wsproto's, so the
	loop never waits on the network. wsproto needs Haxe 4.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeApplication)
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.net.WebSocket)
class NativeWebSocket
{
	#if (haxe4 && (cpp || hl || neko))
	// Lime's own, so a library polling wsproto's shared loop from a thread
	// of its own is not polled here as well
	private static var loop:Loop;
	#end

	private var parent:WebSocket;
	#if (haxe4 && (cpp || hl || neko))
	private var connection:Connection;
	#end

	// What the next connection a client makes starts with
	private var idleTimeout:Int = 60000;
	private var maxMessageSize:Int = 1024 * 1024;
	private var maxQueuedBytes:Int = WebSocket.DEFAULT_MAX_QUEUED_BYTES;
	private var pingInterval:Int = 30000;

	public function new(parent:WebSocket)
	{
		this.parent = parent;
	}

	/**
		Reads, delivers and writes what every connection has, and takes what
		every server has accepted: once a frame, from the application's loop.
	**/
	public static function __update():Void
	{
		#if (haxe4 && (cpp || hl || neko))
		if (loop != null) loop.poll();
		#end
	}

	public function close(code:Int, reason:String):Void
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) connection.close(code, reason);
		#end
	}

	public function connect(url:String, protocols:Array<String>, timeout:Int):Void
	{
		#if (haxe4 && (cpp || hl || neko))
		release();

		var connection = new Connection(getLoop());
		connection.idleTimeout = idleTimeout / 1000;
		connection.maxMessageSize = maxMessageSize;
		connection.maxQueuedBytes = maxQueuedBytes;
		connection.pingInterval = pingInterval / 1000;
		connection.verifyCertificates = parent.verifyCertificates;
		adopt(connection);

		connection.connect(url, protocols, timeout > 0 ? timeout / 1000 : 0);
		#else
		parent.onError.dispatch(WebSocketError.CONNECT_FAILED, "WebSockets are not supported on this target");
		parent.onClose.dispatch(1006, "");
		#end
	}

	public function getBytesPending():Int
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) return connection.bytesPending;
		#end

		return 0;
	}

	public function getExtensions():String
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) return connection.extensions;
		#end

		return "";
	}

	public function getIdleTimeout():Int
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) return Math.round(connection.idleTimeout * 1000);
		#end

		return idleTimeout;
	}

	public function getMaxMessageSize():Int
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) return connection.maxMessageSize;
		#end

		return maxMessageSize;
	}

	public function getMaxQueuedBytes():Int
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) return connection.maxQueuedBytes;
		#end

		return maxQueuedBytes;
	}

	public function getPingInterval():Int
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) return Math.round(connection.pingInterval * 1000);
		#end

		return pingInterval;
	}

	public function getProtocol():String
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) return connection.protocol;
		#end

		return null;
	}

	public function getRemoteAddress():String
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) return connection.remoteAddress;
		#end

		return null;
	}

	public function getRemotePort():Int
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) return connection.remotePort;
		#end

		return 0;
	}

	public function isConnected():Bool
	{
		#if (haxe4 && (cpp || hl || neko))
		return connection != null && connection.connected;
		#else
		return false;
		#end
	}

	public static function isSupported():Bool
	{
		#if (haxe4 && (cpp || hl || neko) && lime_cffi && !macro)
		return true;
		#else
		return false;
		#end
	}

	public function ping(data:Bytes):Void
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null && connection.connected) connection.ping(data);
		#end
	}

	public function send(data:Bytes, offset:Int, length:Int):Bool
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection == null || !connection.connected) return false;
		connection.send(data, offset, length);
		// Closed, if it took what waits past maxQueuedBytes
		return connection != null && connection.connected;
		#else
		return false;
		#end
	}

	public function sendText(text:String):Bool
	{
		#if (haxe4 && (cpp || hl || neko))
		if (connection == null || !connection.connected) return false;
		connection.sendText(text);
		return connection != null && connection.connected;
		#else
		return false;
		#end
	}

	public function setIdleTimeout(value:Int):Void
	{
		idleTimeout = value;
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) connection.idleTimeout = value / 1000;
		#end
	}

	public function setMaxMessageSize(value:Int):Void
	{
		maxMessageSize = value;
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) connection.maxMessageSize = value;
		#end
	}

	public function setMaxQueuedBytes(value:Int):Void
	{
		maxQueuedBytes = value;
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) connection.maxQueuedBytes = value;
		#end
	}

	public function setPingInterval(value:Int):Void
	{
		pingInterval = value;
		#if (haxe4 && (cpp || hl || neko))
		if (connection != null) connection.pingInterval = value / 1000;
		#end
	}

	#if (haxe4 && (cpp || hl || neko))
	// The connection this WebSocket is from now on: a client's, or one a
	// server accepted, open
	private function adopt(connection:Connection):Void
	{
		this.connection = connection;
		connection.onOpen = function() parent.onConnect.dispatch();
		connection.onText = function(text) parent.onText.dispatch(text);
		connection.onBinary = function(data) parent.onData.dispatch(data);
		connection.onError = function(error, message) parent.onError.dispatch((error : Int), message);
		connection.onClose = function(code, reason) parent.onClose.dispatch(code, reason);
	}

	private static function getLoop():Loop
	{
		if (loop == null)
		{
			loop = new Loop();
			NativeApplication.__updateWebSockets = __update;

			#if (!macro && lime_cffi)
			// Haxe's standard library has no secure source for a client's
			// masks and key
			if (Connection.random == null)
			{
				Connection.random = function(bytes, offset, length) return NativeCFFI.lime_system_get_secure_random_bytes(bytes, offset, length);
			}
			#end
		}

		return loop;
	}

	// The connection there was, let go of without events: one still open
	// finishes its closing handshake on its own
	private function release():Void
	{
		var connection = this.connection;
		if (connection == null) return;

		this.connection = null;
		connection.onOpen = null;
		connection.onText = null;
		connection.onBinary = null;
		connection.onError = null;
		connection.onClose = null;
		connection.close(1000);
	}
	#end
}
