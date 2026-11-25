package lime.net;

import lime.app.Event;
import lime.utils.Bytes;

/**
	A WebSocket (RFC 6455): a connection to a `ws://` or `wss://` URL that
	carries whole messages, text or binary, each way. A `WebSocketServer`
	hands one to its `onConnect` for each client it takes.

	The protocol is wsproto's, the library CrossByte's WebSocket runs on, so
	a Lime application and a CrossByte one speak it from the same code. On
	native targets the connection is a socket of Haxe's own (`sys.net`, and
	`sys.ssl` for `wss://`), read and written as the application's loop runs;
	in a browser it is the page's `WebSocket`.

	Example usage:
	```haxe
	var socket = new WebSocket();
	socket.onConnect.add(function() socket.sendText("hello"));
	socket.onText.add(function(text) trace(text));
	socket.onData.add(function(data) trace(data.length + " bytes"));
	socket.onClose.add(function(code, reason) trace("closed " + code + " " + reason));
	socket.onError.add(function(error, message) trace(message));
	socket.connect("wss://example.com/chat", ["chat.v1"]);
	```

	Events are dispatched on the main thread. `isSupported` is true in
	browsers, and on native targets built with Haxe 4.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class WebSocket
{
	/**
		Whether WebSockets are supported on the current platform.
	**/
	public static var isSupported(get, never):Bool;

	/**
		The bytes sent that the network has not taken yet, framing included.
		A sender with a lot to send waits for this to fall, rather than
		passing `maxQueuedBytes`.
	**/
	public var bytesPending(get, never):Int;

	/**
		Whether the connection is open: its opening handshake done, and no
		close begun.
	**/
	public var connected(get, never):Bool;

	/**
		The extensions agreed in the opening handshake, as its
		`Sec-WebSocket-Extensions` names them, or `""` for none.
	**/
	public var extensions(get, never):String;

	/**
		How long, in milliseconds, the connection hears nothing from its peer
		(no message, no pong, no frame at all) before it takes the peer for
		gone: `onError` dispatches `TIMEOUT`, and the connection closes with
		1006. `0` for never. 60000 by default. Native targets only.
	**/
	public var idleTimeout(get, set):Int;

	/**
		The largest message this side takes, in bytes: one that would be
		longer is refused on its first frame's header, and the connection
		closes with 1009. `0` takes messages of any size. 1 MiB by default.
		Native targets only.
	**/
	public var maxMessageSize(get, set):Int;

	/**
		The most that may wait to be sent, in bytes, framing included. A send
		that would take `bytesPending` past it returns `false`: `onError`
		dispatches `OVERFLOW`, and the connection closes with 1011, throwing
		away what waited, so a peer that stops reading is not waited on
		forever. `0` removes the limit. 16 MiB by default.
	**/
	public var maxQueuedBytes(get, set):Int;

	/**
		How often, in milliseconds, a connection that has heard nothing from
		its peer pings it, so a quiet connection whose peer is still there
		stays open through proxies; `0` for never. 30000 by default. Native
		targets only.
	**/
	public var pingInterval(get, set):Int;

	/**
		The subprotocol the connection speaks: the one the server chose from
		those `connect` asked for, or on a server's connection the one it
		accepted. `null` for none.
	**/
	public var protocol(get, never):String;

	/**
		The address of the other end, once connected, or `null`. Native
		targets only.
	**/
	public var remoteAddress(get, never):String;

	/**
		The port of the other end, once connected, or `0`. Native targets
		only.
	**/
	public var remotePort(get, never):Int;

	/**
		The URL `connect` was given, or `null` on a server's connection.
	**/
	public var url(default, null):String;

	/**
		Whether a `wss://` server's certificate is checked against the
		system's trusted authorities and the URL's host name. On by default;
		turn it off only for a server under your own control, such as one
		with a self-signed certificate in development. Set before `connect`.
		Native targets only: a browser always checks.
	**/
	public var verifyCertificates:Bool = true;

	/**
		Dispatched when the connection has ended, with the code and reason
		the closing handshake carried: the peer's, whichever end began it.
		1006 when it ended without one, as a connection that dropped, failed
		or never opened does, after `onError` says why.
	**/
	public var onClose(default, null) = new Event<Int->String->Void>();

	/**
		Dispatched when the opening handshake is done, and messages can be
		sent and received.
	**/
	public var onConnect(default, null) = new Event<Void->Void>();

	/**
		Dispatched for each binary message.
	**/
	public var onData(default, null) = new Event<Bytes->Void>();

	/**
		Dispatched when the connection could not be made, or ended because
		something went wrong: why, and a description of it to log. `onClose`
		follows.
	**/
	public var onError(default, null) = new Event<WebSocketError->String->Void>();

	/**
		Dispatched for each text message.
	**/
	public var onText(default, null) = new Event<String->Void>();

	@:noCompletion private static inline var DEFAULT_MAX_QUEUED_BYTES:Int = 16 * 1024 * 1024;

	@:noCompletion private var __backend:WebSocketBackend;

	public function new()
	{
		__backend = new WebSocketBackend(this);
	}

	/**
		Closes the connection the way RFC 6455 has it closed: a close frame
		with `code` (1000, or 3000 to 4999 for one of the application's own)
		and `reason`, then the peer's answer, then the connection. `onClose`
		is dispatched once that has happened, or after five seconds without
		an answer. A connection not yet open closes at once.
	**/
	public function close(code:Int = 1000, reason:String = null):Void
	{
		__backend.close(code, reason);
	}

	/**
		Connects to `url`, a `ws://` or `wss://` URL, asking for one of
		`protocols` as the subprotocol where there are any. `onConnect` is
		dispatched once the server has accepted, or `onError` and then
		`onClose` if it does not within `timeout` milliseconds (`0` waits as
		long as it takes).

		A connection this `WebSocket` already has is closed first, as `close()`
		closes it but with no events dispatched for it.
	**/
	public function connect(url:String, protocols:Array<String> = null, timeout:Int = 10000):Void
	{
		this.url = url;
		__backend.connect(url, protocols, timeout);
	}

	/**
		Pings the other end, which answers with a pong carrying `data` (at
		most 125 bytes, none by default). Native targets only: a browser pings
		as it sees fit.
	**/
	public function ping(data:Bytes = null):Void
	{
		if (data != null && data.length > 125) return;
		__backend.ping(data);
	}

	/**
		Sends `length` bytes of `data` from `offset` (the rest of it, for a
		`length` of `-1`) as one binary message, without waiting. Returns
		`false` if the connection is not open, or if the message took
		`bytesPending` past `maxQueuedBytes`, which closes it.
	**/
	public function send(data:Bytes, offset:Int = 0, length:Int = -1):Bool
	{
		if (data == null) return false;
		if (length < 0) length = data.length - offset;
		if (offset < 0 || length < 0 || offset + length > data.length) return false;

		return __backend.send(data, offset, length);
	}

	/**
		Sends `text` as one text message, without waiting. Returns `false` if
		the connection is not open, or if the message took `bytesPending` past
		`maxQueuedBytes`, which closes it.
	**/
	public function sendText(text:String):Bool
	{
		if (text == null) return false;
		return __backend.sendText(text);
	}

	// Get & Set Methods
	@:noCompletion private function get_bytesPending():Int
	{
		return __backend.getBytesPending();
	}

	@:noCompletion private function get_connected():Bool
	{
		return __backend.isConnected();
	}

	@:noCompletion private function get_extensions():String
	{
		return __backend.getExtensions();
	}

	@:noCompletion private function get_idleTimeout():Int
	{
		return __backend.getIdleTimeout();
	}

	@:noCompletion private function set_idleTimeout(value:Int):Int
	{
		if (value < 0) value = 0;
		__backend.setIdleTimeout(value);
		return value;
	}

	@:noCompletion private static function get_isSupported():Bool
	{
		return WebSocketBackend.isSupported();
	}

	@:noCompletion private function get_maxMessageSize():Int
	{
		return __backend.getMaxMessageSize();
	}

	@:noCompletion private function set_maxMessageSize(value:Int):Int
	{
		if (value < 0) value = 0;
		__backend.setMaxMessageSize(value);
		return value;
	}

	@:noCompletion private function get_maxQueuedBytes():Int
	{
		return __backend.getMaxQueuedBytes();
	}

	@:noCompletion private function set_maxQueuedBytes(value:Int):Int
	{
		if (value < 0) value = 0;
		__backend.setMaxQueuedBytes(value);
		return value;
	}

	@:noCompletion private function get_pingInterval():Int
	{
		return __backend.getPingInterval();
	}

	@:noCompletion private function set_pingInterval(value:Int):Int
	{
		if (value < 0) value = 0;
		__backend.setPingInterval(value);
		return value;
	}

	@:noCompletion private function get_protocol():String
	{
		return __backend.getProtocol();
	}

	@:noCompletion private function get_remoteAddress():String
	{
		return __backend.getRemoteAddress();
	}

	@:noCompletion private function get_remotePort():Int
	{
		return __backend.getRemotePort();
	}
}

#if flash
@:noCompletion private typedef WebSocketBackend = lime._internal.backend.flash.FlashWebSocket;
#elseif (js && html5)
@:noCompletion private typedef WebSocketBackend = lime._internal.backend.html5.HTML5WebSocket;
#else
@:noCompletion private typedef WebSocketBackend = lime._internal.backend.native.NativeWebSocket;
#end
