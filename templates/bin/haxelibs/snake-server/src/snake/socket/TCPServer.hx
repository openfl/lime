package snake.socket;

import haxe.Exception;
import sys.net.Host;
#if (eval && (haxe_ver >= 4.2))
import snake._internal.net.Socket as Socket;
#else
import sys.net.Socket;
#end

/**
	Base class for various socket-based server classes.

	Defaults to synchronous IP stream (i.e., TCP).
**/
class TCPServer extends BaseServer {
	/**
		The number of pending connection until some get rejected. Passed to
		`socket.listen()`.
	**/
	public var requestQueueSize:Int = 5;

	/**
		Constructor.  May be extended, do not override.
	**/
	public function new(serverHost:Host, serverPort:Int, requestHandlerClass:Class<BaseRequestHandler>, bindAndActivate:Bool = true) {
		super(serverHost, serverPort, requestHandlerClass);
		socket = new Socket();
		if (bindAndActivate) {
			try {
				serverBind();
				serverActivate();
			} catch (e:Exception) {
				serverClose();
				throw e;
			}
		}
	}

	/**
		Called by constructor to bind the socket.

		May be overridden.
	**/
	public function serverBind():Void {
		socket.bind(serverAddress.host, serverAddress.port);
		serverAddress = socket.host();
	}

	/**
		Called by constructor to activate the server.

		May be overridden.
	**/
	override public function serverActivate():Void {
		socket.listen(requestQueueSize);
	}

	/**
		Called to clean-up the server.

		May be overridden.
	**/
	override private function serverClose():Void {
		socket.close();
	}

	/**
		Get the request and client address from the socket.

		May be overridden.
	**/
	override private function getRequest():Socket {
		return socket.accept();
	}

	/**
		Called to shutdown and close an individual request.
	**/
	override private function shutdownRequest(request:Socket):Void {
		// commented out because it results in an exception that doesn't
		// seem to be caught
		/*try {
				// explicitly shutdown.  socket.close() merely releases
				// the socket and waits for GC to perform the actual close.
				request.shutdown(false, true);
			} catch (e:Exception) {
				// some platforms may raise ENOTCONN here
		}*/
		closeRequest(request);
	}

	/**
		Called to clean up an individual request.
	**/
	override private function closeRequest(request:Socket):Void {
		try {
			request.close();
		} catch (e:Exception) {}
	}
}
