package lime.net;

/**
	Why a `LocalSocket` could not connect, or why it ended, as its `onError`
	dispatches it; and why a `LocalServer` could not listen, as its `error`
	says.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract LocalSocketError(Int) from Int to Int
{
	/**
		Nothing went wrong.
	**/
	public var NONE = 0;

	/**
		The name cannot be used, or the connection could not be made.
	**/
	public var FAILED = 1;

	/**
		What is under the name is not this user's own. On Linux and macOS, the
		directory names live in (`/tmp/native-ipc-<uid>`) must be a directory
		this user owns that nobody else can enter.
	**/
	public var NOT_OWNED = 2;

	/**
		The other end does not speak the same protocol, or the same version of
		it.
	**/
	public var PROTOCOL_MISMATCH = 3;

	/**
		Another server of this user's is listening on the name.
	**/
	public var NAME_IN_USE = 4;

	/**
		Nothing listening on the name took the connection in the time allowed.
	**/
	public var TIMEOUT = 5;

	/**
		The other end left more unread than `maxQueuedBytes` allows, and the
		connection was closed.
	**/
	public var OVERFLOW = 6;

	/**
		The other end sent something that is not a message, and the connection
		was closed.
	**/
	public var INVALID_MESSAGE = 7;
}
