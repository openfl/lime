package lime.net;

import lime.app.Event;

/**
	Listens for `LocalSocket` connections from processes of the same user on
	this machine, on a name of the application's choosing. Each connection it
	takes is dispatched by `onConnect` as a `LocalSocket` of its own, and any
	number may be open at once.

	A name belongs to the user: processes of other users cannot connect to
	it, listen on it, or take it over. Only one server of the user's can
	listen on a name at a time.

	Example usage:
	```haxe
	var server = new LocalServer();
	server.onConnect.add(function(socket) {
		socket.onData.add(function(data) socket.send(data));
	});

	if (!server.listen("my-app"))
	{
		trace("could not listen: " + server.error);
	}
	```

	Events are dispatched on the main thread. `isSupported` is true on
	Windows, macOS and Linux.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class LocalServer
{
	/**
		Whether local servers are supported on the current platform.
	**/
	public static var isSupported(get, never):Bool;

	/**
		Why the last `listen` failed, or `NONE`.
	**/
	public var error(default, null):LocalSocketError = NONE;

	/**
		Whether the server is listening.
	**/
	public var listening(get, never):Bool;

	/**
		The name the server listens on, or `null`.
	**/
	public var name(default, null):String;

	/**
		Dispatched for each connection the server takes, already connected.
	**/
	public var onConnect(default, null) = new Event<LocalSocket->Void>();

	@:noCompletion private var __backend:LocalServerBackend;

	public function new()
	{
		__backend = new LocalServerBackend(this);
	}

	/**
		Stops listening. Connections already taken stay open until they are
		closed.
	**/
	public function close():Void
	{
		__backend.close();
		name = null;
	}

	/**
		Listens on `name`, closing what this server listened on before.
		Returns `false` if it cannot, and `error` says why: `NAME_IN_USE` when
		another server of this user's has the name.
	**/
	public function listen(name:String):Bool
	{
		close();
		error = __backend.listen(name);

		if (error == NONE)
		{
			this.name = name;
			return true;
		}

		return false;
	}

	// Get & Set Methods
	@:noCompletion private static function get_isSupported():Bool
	{
		return LocalServerBackend.isSupported();
	}

	@:noCompletion private function get_listening():Bool
	{
		return __backend.listening;
	}
}

#if flash
@:noCompletion private typedef LocalServerBackend = lime._internal.backend.flash.FlashLocalServer;
#elseif (js && html5)
@:noCompletion private typedef LocalServerBackend = lime._internal.backend.html5.HTML5LocalServer;
#else
@:noCompletion private typedef LocalServerBackend = lime._internal.backend.native.NativeLocalServer;
#end
