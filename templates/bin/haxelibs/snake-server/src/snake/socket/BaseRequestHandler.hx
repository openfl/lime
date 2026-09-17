package snake.socket;

import haxe.Exception;
import sys.net.Host;
#if (eval && (haxe_ver >= 4.2))
import snake._internal.net.Socket as Socket;
#else
import sys.net.Socket;
#end

/**
	Base class for request handler classes.
**/
class BaseRequestHandler {
	private var request:Socket;
	private var clientAddress:{host:Host, port:Int};
	private var server:BaseServer;

	/**
		Constructor.
	**/
	public function new(request:Socket, clientAddress:{host:Host, port:Int}, server:BaseServer) {
		this.request = request;
		this.clientAddress = clientAddress;
		this.server = server;
		setup();
		try {
			handle();
		} catch (e:Exception) {
			finish();
			throw e;
		}
		finish();
	}

	private function setup():Void {}

	private function handle():Void {}

	private function finish():Void {}
}
