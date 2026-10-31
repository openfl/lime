package lime.net;

import lime.app.Event;
import lime.utils.Bytes;

/**
	A connection to another process of the same user on this machine, made to
	a `LocalServer` listening on a name. Each `send` arrives as one `onData`,
	whole and in order.

	Connections are made with native-ipc, which other frameworks share: the
	other end can be any program that speaks its protocol, such as a CrossByte
	application's `LocalConnection`. On Windows a name is a named pipe, and on
	Linux and macOS a Unix domain socket; either way it is the user's own, so
	processes of other users cannot connect to it, listen on it, or read what
	is sent.

	Example usage:
	```haxe
	var socket = new LocalSocket();
	socket.onConnect.add(function() socket.send(Bytes.ofString("hello")));
	socket.onData.add(function(data) trace(data.toString()));
	socket.onError.add(function(error) trace("error " + error));
	socket.connect("my-app");
	```

	Events are dispatched on the main thread. `isSupported` is true on
	Windows, macOS and Linux.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class LocalSocket
{
	/**
		The longest message `send` takes, in bytes.
	**/
	public static inline var MAX_MESSAGE_SIZE:Int = 8 * 1024 * 1024;

	/**
		Whether local sockets are supported on the current platform.
	**/
	public static var isSupported(get, never):Bool;

	/**
		The bytes `send` has queued that the other end has not taken yet,
		framing included. A sender with a lot to send waits for this to fall,
		rather than passing `maxQueuedBytes`.
	**/
	public var bytesPending(get, never):Int;

	/**
		Whether the connection is open.
	**/
	public var connected(get, never):Bool;

	/**
		The most this connection holds in each direction, in bytes: what
		`send` has queued that the other end has not read, and what has
		arrived that has not been dispatched yet.

		Past the first, the connection is closed with `OVERFLOW`. Past the
		second, it stops reading, and the other end waits. `0` removes both
		limits. The default holds two messages of the largest size.
	**/
	public var maxQueuedBytes(get, set):Int;

	/**
		The name this socket connected to, or `null`.
	**/
	public var name(default, null):String;

	/**
		Dispatched when the connection has ended, whichever end closed it,
		after `onError` if it ended because something went wrong. Not
		dispatched for `close()`.
	**/
	public var onClose(default, null) = new Event<Void->Void>();

	/**
		Dispatched when a connection started with `connect` has been made.
	**/
	public var onConnect(default, null) = new Event<Void->Void>();

	/**
		Dispatched for each message the other end sent.
	**/
	public var onData(default, null) = new Event<Bytes->Void>();

	/**
		Dispatched when a connection could not be made, or ended because
		something went wrong.
	**/
	public var onError(default, null) = new Event<LocalSocketError->Void>();

	@:noCompletion private var __backend:LocalSocketBackend;

	public function new()
	{
		__backend = new LocalSocketBackend(this);
	}

	/**
		Closes the connection. Anything still queued to send is dropped.
	**/
	public function close():Void
	{
		__backend.close();
	}

	/**
		Connects to the `LocalServer` listening on `name`. `onConnect` is
		dispatched once it has taken the connection, or `onError` and then
		`onClose` if nothing did within `timeout` milliseconds. A `timeout` of
		`0` waits for as long as it takes.

		What is sent before the connection is made is sent once it is.
	**/
	public function connect(name:String, timeout:Int = 5000):Void
	{
		this.name = name;
		__backend.connect(name, timeout);
	}

	/**
		Sends `length` bytes of `data` from `offset` (the rest of it, for a
		`length` of `-1`) as one message, without waiting.

		Returns `false` if the connection has ended, the message is longer than
		`MAX_MESSAGE_SIZE`, or it would take `bytesPending` past
		`maxQueuedBytes`, which closes the connection with `OVERFLOW`.
	**/
	public function send(data:Bytes, offset:Int = 0, length:Int = -1):Bool
	{
		if (data == null) return false;
		if (length < 0) length = data.length - offset;
		if (offset < 0 || length < 0 || offset + length > data.length || length > MAX_MESSAGE_SIZE) return false;

		return __backend.send(data, offset, length);
	}

	// Get & Set Methods
	@:noCompletion private function get_bytesPending():Int
	{
		return __backend.getBytesPending();
	}

	@:noCompletion private function get_connected():Bool
	{
		return __backend.connected;
	}

	@:noCompletion private static function get_isSupported():Bool
	{
		return LocalSocketBackend.isSupported();
	}

	@:noCompletion private function get_maxQueuedBytes():Int
	{
		return __backend.maxQueuedBytes;
	}

	@:noCompletion private function set_maxQueuedBytes(value:Int):Int
	{
		if (value < 0) value = 0;
		__backend.setMaxQueuedBytes(value);
		return value;
	}
}

#if flash
@:noCompletion private typedef LocalSocketBackend = lime._internal.backend.flash.FlashLocalSocket;
#elseif (js && html5)
@:noCompletion private typedef LocalSocketBackend = lime._internal.backend.html5.HTML5LocalSocket;
#else
@:noCompletion private typedef LocalSocketBackend = lime._internal.backend.native.NativeLocalSocket;
#end
