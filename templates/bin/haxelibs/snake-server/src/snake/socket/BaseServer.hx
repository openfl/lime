package snake.socket;

import haxe.Exception;
import sys.net.Host;
import sys.thread.Mutex;
import sys.thread.Thread;
#if (eval && (haxe_ver >= 4.2))
import snake._internal.net.Socket as Socket;
#else
import sys.net.Socket;
#end

/**
	Base class for server classes.
**/
class BaseServer {
	/**
		A timeout to apply to the request socket, if not `null`.
	**/
	public var timeout:Null<Float> = null;

	/**
		Handle each request in a new thread.
	**/
	public var threading:Bool = false;

	private var serverAddress:{host:Host, port:Int};
	private var socket:Socket;
	private var requestHandlerClass:Class<BaseRequestHandler>;
	private var __shutdownRequest = false;
	private var __isShutDown:Mutex;

	public function new(serverHost:Host, serverPort:Int, requestHandlerClass:Class<BaseRequestHandler>) {
		this.serverAddress = {host: serverHost, port: serverPort};
		this.requestHandlerClass = requestHandlerClass;
		__isShutDown = new Mutex();
	}

	/**
		Called by constructor to activate the server.

		May be overridden.
	**/
	public function serverActivate():Void {}

	/**
		Handle one request at a time until shutdown.
	**/
	public function serveForever(pollInterval:Float = 0.5):Void {
		__isShutDown.acquire();
		try {
			while (!__shutdownRequest) {
				var ready = Socket.select([socket], null, null, pollInterval);
				if (__shutdownRequest) {
					// bpo-35017: shutdown() called during select(), exit immediately.
					break;
				}
				if (ready.read.length == 1) {
					handleRequestNoBlock();
				}
				serviceActions();
			}
		} catch (e:Exception) {
			__isShutDown.release();
			throw e;
		}
		__isShutDown.release();
	}

	/**
		Stops the `serveForever()` loop.

		Blocks until the loop has finished. This must be called while
		`serveForever()` is running in another thread, or it will deadlock.
	**/
	public function shutdown():Void {
		__shutdownRequest = true;
		__isShutDown.acquire();
	}

	/**
		Called by the serveForever() loop.

		May be overridden by a subclass / Mixin to implement any code that
		needs to be run during the loop.
	**/
	private function serviceActions():Void {}

	/**
		Handle one request, possibly blocking.
	**/
	public function handleRequest():Void {
		var ready = Socket.select([socket], null, null, timeout);
		if (ready.read.length == 1) {
			handleRequestNoBlock();
		} else {
			handleTimeout();
		}
	}

	/**
		Handle one request, without blocking.

		I assume that `Socket.select()` has returned that the socket is
		readable before this function was called, so there should be no risk of
		blocking in `getRequest()`.
	**/
	private function handleRequestNoBlock():Void {
		var request:Socket = null;
		try {
			request = getRequest();
		} catch (e:Exception) {
			return;
		}
		var clientAddress = request.peer();
		if (verifyRequest(request, clientAddress)) {
			try {
				processRequest(request, clientAddress);
			} catch (e:Exception) {
				handleError(request, clientAddress);
				shutdownRequest(request);
			}
		} else {
			shutdownRequest(request);
		}
	}

	/**
		Called if no new request arrives within `timeout`.
	**/
	private function handleTimeout():Void {}

	/**
		Verify the request.  May be overridden.

		@return true if we should proceed with this request.
	**/
	private function verifyRequest(request:Socket, clientAddress:{host:Host, port:Int}):Bool {
		return true;
	}

	/**
		Call `finishRequest`.
	**/
	private function processRequest(request:Socket, clientAddress:{host:Host, port:Int}):Void {
		if (threading) {
			Thread.create(() -> {
				try {
					finishRequest(request, clientAddress);
				} catch (e:Exception) {
					handleError(request, clientAddress);
				}
				shutdownRequest(request);
			});
		} else {
			finishRequest(request, clientAddress);
			shutdownRequest(request);
		}
	}

	/**
		Called to clean-up the server.

		May be overridden.
	**/
	private function serverClose():Void {}

	/**
		Finish one request by instantiating `requestHandlerClass`.
	**/
	private function finishRequest(request:Socket, clientAddress:{host:Host, port:Int}):Void {
		Type.createInstance(requestHandlerClass, [request, clientAddress, this]);
	}

	/**
		Called to shutdown and close an individual request.
	**/
	private function shutdownRequest(request:Socket):Void {}

	/**
		Called to clean up an individual request.
	**/
	private function closeRequest(request:Socket):Void {}

	/**
		Handle an error gracefully.  May be overridden.

		The default is to print a traceback and continue.
	**/
	private function handleError(request:Socket, clientAddress:{host:Host, port:Int}):Void {
		Sys.print('Exception occurred during processing of request from ${clientAddress.host.toString()}:${clientAddress.port}\n');
	}

	/**
		Get the request and client address from the socket.

		May be overridden.
	**/
	private function getRequest():Socket {
		return null;
	}
}
