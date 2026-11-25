package lime.net;

import lime.app.Event;

/**
	Listens for WebSocket connections on a TCP port. Each client whose
	opening handshake it accepts is dispatched by `onConnect` as a
	`WebSocket` of its own, already connected, and any number may be open at
	once.

	The protocol is wsproto's, as `WebSocket`'s is, so browsers, CrossByte
	programs and Lime applications all connect to it alike. Connections are
	plain `ws://`, or `wss://` once `setCertificate` has given the server a
	certificate.

	Example usage:
	```haxe
	var server = new WebSocketServer();
	server.onConnect.add(function(socket) {
		socket.onText.add(function(text) socket.sendText(text));
	});

	if (!server.listen(8080))
	{
		trace("could not listen: " + server.error);
	}
	```

	Events are dispatched on the main thread. `isSupported` is true on
	native targets built with Haxe 4; a browser cannot listen.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class WebSocketServer
{
	/**
		Whether WebSocket servers are supported on the current platform.
	**/
	public static var isSupported(get, never):Bool;

	/**
		Why the last `listen` failed, or `NONE`.
	**/
	public var error(default, null):WebSocketError = NONE;

	/**
		Whether the server is listening.
	**/
	public var listening(get, never):Bool;

	/**
		The port the server listens on, which `listen(0)` leaves to the
		system, or `0`.
	**/
	public var localPort(get, never):Int;

	/**
		The subprotocols this server speaks, in its order of preference: a
		client asking for any of them is given the first of them it asked
		for, and one asking for none of them is accepted without a
		subprotocol. `null`, the default, accepts the first a client asks
		for.
	**/
	public var protocols(get, set):Array<String>;

	/**
		Dispatched for each connection the server accepts, once its opening
		handshake is done.
	**/
	public var onConnect(default, null) = new Event<WebSocket->Void>();

	@:noCompletion private var __backend:WebSocketServerBackend;

	public function new()
	{
		__backend = new WebSocketServerBackend(this);
	}

	#if sys
	/**
		Serves `certificate` and `key` to a client whose TLS handshake asks for
		a host name `match` accepts, in place of the one `setCertificate` set:
		several names on one port. Takes effect on the next `listen`. Native
		targets only.
	**/
	public function addSNICertificate(match:String->Bool, certificate:sys.ssl.Certificate, key:sys.ssl.Key):Void
	{
		__backend.addSNICertificate(match, certificate, key);
	}
	#end

	/**
		Stops listening. Connections already accepted stay open until they
		are closed.
	**/
	public function close():Void
	{
		__backend.close();
	}

	/**
		Listens on `port` of `host` (every interface by default), closing what
		this server listened on before. A `port` of `0` takes any free one,
		which `localPort` then says. Returns `false` if it cannot listen
		there, and `error` says why.
	**/
	public function listen(port:Int, host:String = "0.0.0.0", backlog:Int = 64):Bool
	{
		close();
		error = __backend.listen(port, host, backlog);
		return error == NONE;
	}

	#if sys
	/**
		Serves `wss://` with `certificate` and its `key`, from the next `listen`
		on. A client then has ten seconds to finish its TLS handshake and its
		WebSocket upgrade. Native targets only.
	**/
	public function setCertificate(certificate:sys.ssl.Certificate, key:sys.ssl.Key):Void
	{
		__backend.setCertificate(certificate, key);
	}
	#end

	// Get & Set Methods
	@:noCompletion private static function get_isSupported():Bool
	{
		return WebSocketServerBackend.isSupported();
	}

	@:noCompletion private function get_listening():Bool
	{
		return __backend.listening;
	}

	@:noCompletion private function get_localPort():Int
	{
		return __backend.getLocalPort();
	}

	@:noCompletion private function get_protocols():Array<String>
	{
		return __backend.getProtocols();
	}

	@:noCompletion private function set_protocols(value:Array<String>):Array<String>
	{
		__backend.setProtocols(value);
		return value;
	}
}

#if flash
@:noCompletion private typedef WebSocketServerBackend = lime._internal.backend.flash.FlashWebSocketServer;
#elseif (js && html5)
@:noCompletion private typedef WebSocketServerBackend = lime._internal.backend.html5.HTML5WebSocketServer;
#else
@:noCompletion private typedef WebSocketServerBackend = lime._internal.backend.native.NativeWebSocketServer;
#end
