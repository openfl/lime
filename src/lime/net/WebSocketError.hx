package lime.net;

/**
	Why a `WebSocket` could not connect, or why it ended, as its `onError`
	dispatches it; and why a `WebSocketServer` could not listen, as its
	`error` says. A `WebSocket`'s `onClose` follows each error it dispatches.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract WebSocketError(Int) from Int to Int
{
	/**
		Nothing went wrong.
	**/
	public var NONE = 0;

	/**
		The connection could not be made: the URL is not a `ws://` or `wss://`
		one, its host name did not resolve, nothing took the TCP connection, or
		the TLS handshake failed, as it does for a certificate that is not
		trusted.
	**/
	public var CONNECT_FAILED = 1;

	/**
		The connection, or its opening handshake, took longer than allowed; or
		nothing was heard from the other end for `idleTimeout`.
	**/
	public var TIMEOUT = 2;

	/**
		The server refused the WebSocket upgrade, or did not answer it as a
		WebSocket server does.
	**/
	public var REFUSED = 3;

	/**
		More than `maxQueuedBytes` waited to be sent, because the other end
		stopped reading, and the connection was closed.
	**/
	public var OVERFLOW = 4;

	/**
		The server could not listen on the port and host given: another
		program has the port, the port needs privileges this one lacks, or the
		host is not an address of this machine.
	**/
	public var LISTEN_FAILED = 5;
}
