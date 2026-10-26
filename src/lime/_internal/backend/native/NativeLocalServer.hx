package lime._internal.backend.native;

import lime.net.LocalServer;
import lime.net.LocalSocket;
import lime.net.LocalSocketError;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime._internal.backend.native.NativeLocalSocket)
@:access(lime.net.LocalSocket)
class NativeLocalServer
{
	private static var serversByID = new Map<Int, NativeLocalServer>();

	public var handle:Dynamic;
	public var listening(get, never):Bool;

	private var id:Int;
	private var parent:LocalServer;

	public function new(parent:LocalServer)
	{
		this.parent = parent;
		id = -1;
	}

	public function close():Void
	{
		if (handle != null)
		{
			#if (!macro && lime_cffi)
			NativeCFFI.lime_local_socket_close(handle);
			#end

			serversByID.remove(id);
			handle = null;
		}
	}

	public static function getServer(id:Int):NativeLocalServer
	{
		return serversByID.get(id);
	}

	public function handleAccept():Void
	{
		#if (!macro && lime_cffi)
		var accepted = NativeCFFI.lime_local_socket_get_accepted();

		if (accepted != null)
		{
			var socket = new LocalSocket();
			socket.__backend.adopt(accepted, parent.name);
			parent.onConnect.dispatch(socket);
		}
		#end
	}

	public static function isSupported():Bool
	{
		return NativeLocalSocket.isSupported();
	}

	public function listen(name:String):LocalSocketError
	{
		#if (!macro && lime_cffi)
		handle = NativeCFFI.lime_local_socket_listen(name);

		if (handle == null)
		{
			return NativeCFFI.lime_local_socket_get_last_error();
		}

		id = NativeCFFI.lime_local_socket_get_id(handle);
		serversByID.set(id, this);
		return NONE;
		#else
		return FAILED;
		#end
	}

	// Get & Set Methods
	private function get_listening():Bool
	{
		return handle != null;
	}
}
