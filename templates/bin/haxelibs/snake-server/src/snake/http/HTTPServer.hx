package snake.http;

import snake.socket.BaseRequestHandler;
import snake.socket.TCPServer;
import sys.net.Host;

class HTTPServer extends TCPServer {
	/**
		Constructor.  May be extended, do not override.
	**/
	public function new(serverHost:Host, serverPort:Int, requestHandlerClass:Class<BaseRequestHandler>, bindAndActivate:Bool = true) {
		super(serverHost, serverPort, requestHandlerClass, bindAndActivate);
	}
}
