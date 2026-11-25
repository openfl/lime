package lime._internal.backend.html5;

import haxe.Timer;
import js.Browser;
import lime.net.LocalServer;
import lime.net.LocalSocket;
import lime.net.LocalSocketError;

/**
	Listens for connections from pages of the same origin, as
	`HTML5LocalSocket` describes. A server that finds the name taken, from the
	answer to the probe it sends as it starts listening, stops listening, and
	its `error` becomes `NAME_IN_USE`. Of two servers that start at once, the
	one with the lower ID keeps the name.
**/
@:access(lime._internal.backend.html5.HTML5LocalSocket)
@:access(lime.net.LocalServer)
@:access(lime.net.LocalSocket)
class HTML5LocalServer
{
	// Long enough for the pages already listening to answer the probe
	private static inline var CLAIM_MS:Int = 250;

	public var listening(default, null):Bool = false;

	private var accepted:Map<String, Bool>;
	private var channel:Dynamic;
	private var claimTimer:Timer;
	private var claiming:Bool = false;
	private var id:String;
	private var name:String;
	private var parent:LocalServer;

	public function new(parent:LocalServer)
	{
		this.parent = parent;
	}

	public function close():Void
	{
		if (claimTimer != null)
		{
			claimTimer.stop();
			claimTimer = null;
		}

		if (channel != null)
		{
			channel.onmessage = null;
			channel.close();
			channel = null;
		}

		accepted = null;
		claiming = false;
		listening = false;
	}

	public static function isSupported():Bool
	{
		return HTML5LocalSocket.isSupported();
	}

	public function listen(name:String):LocalSocketError
	{
		close();

		if (!isSupported()) return FAILED;

		this.name = name;
		id = HTML5LocalSocket.createID();
		accepted = new Map();
		channel = untyped #if haxe4 js.Syntax.code #else __js__ #end ("new BroadcastChannel({0})", HTML5LocalSocket.channelName(name));
		channel.onmessage = handleMessage;
		listening = true;

		// Whether the name is taken is only known once the other pages answer
		claiming = true;
		claimTimer = Timer.delay(function()
		{
			claimTimer = null;
			claiming = false;
		}, CLAIM_MS);

		channel.postMessage({t: "probe", s: id});
		return NONE;
	}

	@:noCompletion private function handleMessage(event:Dynamic):Void
	{
		var message:Dynamic = event.data;
		if (message == null || !listening) return;

		switch (message.t)
		{
			case "probe":
				// While both are claiming the name, the lower ID keeps it
				if (message.s != id && (!claiming || id < message.s))
				{
					channel.postMessage({t: "taken", s: id, to: message.s});
				}

			case "taken":
				if (message.to != id) return;
				close();
				parent.error = NAME_IN_USE;
				parent.name = null;

			case "connect":
				var connectionID:String = message.c;
				if (connectionID == null) return;

				// The socket asks again until it is answered
				if (accepted.exists(connectionID))
				{
					channel.postMessage({t: "accept", c: connectionID, s: id});
					return;
				}

				accepted.set(connectionID, true);

				// Its own channel is open before the answer, so nothing sent after the answer is missed
				var socket = new LocalSocket();
				socket.__backend.adopt(name, connectionID, id);
				channel.postMessage({t: "accept", c: connectionID, s: id});
				parent.onConnect.dispatch(socket);

			default:
		}
	}
}
