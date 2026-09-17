package snake.socket;

import haxe.Exception;
import haxe.io.Output;
import haxe.io.Input;
import sys.net.Host;
#if (eval && (haxe_ver >= 4.2))
import snake._internal.net.Socket as Socket;
#else
import sys.net.Socket;
#end

/**
	Define `rfile` and `wfile` for stream sockets.
**/
class StreamRequestHandler extends BaseRequestHandler {
	/**
		A timeout to apply to the request socket, if not `null`.
	**/
	public var timeout:Null<Float> = null;

	/**
		Disable nagle algorithm for this socket, if `true`.
		Use only when wbufsize != 0, to avoid small packets.
	**/
	public var disableNagleAlgorithm:Bool = false;

	private var connection:Socket;
	private var rfile:Input;
	private var wfile:Output;

	/**
		Constructor.
	**/
	public function new(request:Socket, clientAddress:{host:Host, port:Int}, server:BaseServer) {
		super(request, clientAddress, server);
	}

	override private function setup():Void {
		connection = cast(request, Socket);
		if (disableNagleAlgorithm) {
			connection.setFastSend(true);
		}
		if (timeout != null) {
			connection.setTimeout(timeout);
		}
		rfile = connection.input;
		wfile = connection.output;
	}

	override private function finish():Void {
		try {
			wfile.flush();
		} catch (e:Exception) {
			// A final socket error may have occurred here, such as
			// the local error ECONNABORTED.
		}
		connection.close();
	}
}
