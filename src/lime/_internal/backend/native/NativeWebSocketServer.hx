package lime._internal.backend.native;

import lime.net.WebSocket;
import lime.net.WebSocketError;
import lime.net.WebSocketServer;
#if (haxe4 && (cpp || hl || neko))
import wsproto.socket.Server;
#end

/**
	A WebSocket server's native side: a `Server` of wsproto's, on the loop
	Lime's connections are polled on. Each connection it accepts is handed to
	a `WebSocket` of its own once its opening handshake is done.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeWebSocket)
@:access(lime.net.WebSocket)
class NativeWebSocketServer
{
	public var listening(get, never):Bool;

	private var parent:WebSocketServer;
	private var protocols:Array<String> = null;
	#if (haxe4 && (cpp || hl || neko))
	private var server:Server;
	#end

	public function new(parent:WebSocketServer)
	{
		this.parent = parent;
	}

	#if sys
	public function addSNICertificate(match:String->Bool, certificate:sys.ssl.Certificate, key:sys.ssl.Key):Void
	{
		#if (haxe4 && (cpp || hl || neko))
		getServer().addSNICertificate(match, certificate, key);
		#end
	}
	#end

	public function close():Void
	{
		#if (haxe4 && (cpp || hl || neko))
		if (server != null) server.close();
		#end
	}

	public function getLocalPort():Int
	{
		#if (haxe4 && (cpp || hl || neko))
		if (server != null) return server.localPort;
		#end

		return 0;
	}

	public function getProtocols():Array<String>
	{
		return protocols;
	}

	public static function isSupported():Bool
	{
		return NativeWebSocket.isSupported();
	}

	public function listen(port:Int, host:String, backlog:Int):WebSocketError
	{
		#if (haxe4 && (cpp || hl || neko))
		return getServer().listen(port, host, backlog) ? WebSocketError.NONE : WebSocketError.LISTEN_FAILED;
		#else
		return WebSocketError.LISTEN_FAILED;
		#end
	}

	#if sys
	public function setCertificate(certificate:sys.ssl.Certificate, key:sys.ssl.Key):Void
	{
		#if (haxe4 && (cpp || hl || neko))
		getServer().setCertificate(certificate, key);
		#end
	}
	#end

	public function setProtocols(value:Array<String>):Void
	{
		protocols = value;
		#if (haxe4 && (cpp || hl || neko))
		if (server != null) server.protocols = value;
		#end
	}

	#if (haxe4 && (cpp || hl || neko))
	private function getServer():Server
	{
		if (server == null)
		{
			server = new Server(NativeWebSocket.getLoop());
			server.maxQueuedBytes = WebSocket.DEFAULT_MAX_QUEUED_BYTES;
			server.protocols = protocols;
			server.onConnection = function(connection)
			{
				var socket = new WebSocket();
				socket.__backend.adopt(connection);
				parent.onConnect.dispatch(socket);
			};
		}

		return server;
	}
	#end

	// Get & Set Methods
	private function get_listening():Bool
	{
		#if (haxe4 && (cpp || hl || neko))
		return server != null && server.listening;
		#else
		return false;
		#end
	}
}
