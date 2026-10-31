package lime._internal.backend.native;

import lime.net.LocalSocket;
import lime.net.LocalSocketError;
import lime.utils.Bytes;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.net.LocalSocket)
class NativeLocalSocket
{
	// native-ipc's default: two messages of the largest size, with their lengths
	private static inline var DEFAULT_MAX_QUEUED:Int = 2 * (LocalSocket.MAX_MESSAGE_SIZE + 4);

	private static var socketsByID = new Map<Int, NativeLocalSocket>();

	public var connected(default, null):Bool;
	public var handle:Dynamic;
	public var maxQueuedBytes(default, null):Int;

	private var id:Int;
	private var parent:LocalSocket;

	public function new(parent:LocalSocket)
	{
		this.parent = parent;
		connected = false;
		id = -1;
		maxQueuedBytes = DEFAULT_MAX_QUEUED;
	}

	public function close():Void
	{
		if (handle != null)
		{
			#if (!macro && lime_cffi)
			NativeCFFI.lime_local_socket_close(handle);
			#end

			socketsByID.remove(id);
			handle = null;
		}

		connected = false;
	}

	public function connect(name:String, timeout:Int):Void
	{
		close();

		#if (!macro && lime_cffi)
		setHandle(NativeCFFI.lime_local_socket_connect(name, timeout > 0 ? timeout : 0));
		#end
	}

	public function getBytesPending():Int
	{
		#if (!macro && lime_cffi)
		if (handle != null) return NativeCFFI.lime_local_socket_get_bytes_pending(handle);
		#end

		return 0;
	}

	public static function getSocket(id:Int):NativeLocalSocket
	{
		return socketsByID.get(id);
	}

	public function handleClose():Void
	{
		close();
		parent.onClose.dispatch();
	}

	public function handleConnect():Void
	{
		connected = true;
		parent.onConnect.dispatch();
	}

	public function handleData(length:Int):Void
	{
		var data = Bytes.alloc(length);

		#if (!macro && lime_cffi)
		if (length > 0) NativeCFFI.lime_local_socket_read(data);
		#end

		parent.onData.dispatch(data);
	}

	public function handleError(error:Int):Void
	{
		parent.onError.dispatch((error : LocalSocketError));
	}

	public static function isSupported():Bool
	{
		#if (!macro && lime_cffi)
		return NativeCFFI.lime_local_socket_is_supported();
		#else
		return false;
		#end
	}

	public function send(data:Bytes, offset:Int, length:Int):Bool
	{
		#if (!macro && lime_cffi)
		if (handle != null) return NativeCFFI.lime_local_socket_send(handle, data, offset, length);
		#end

		return false;
	}

	public function setMaxQueuedBytes(value:Int):Void
	{
		maxQueuedBytes = value;

		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_local_socket_set_max_queued(handle, value);
		#end
	}

	// A connection a server took, already connected
	private function adopt(handle:Dynamic, name:String):Void
	{
		parent.name = name;
		connected = true;
		setHandle(handle);
	}

	private function setHandle(handle:Dynamic):Void
	{
		this.handle = handle;

		#if (!macro && lime_cffi)
		if (handle != null)
		{
			id = NativeCFFI.lime_local_socket_get_id(handle);
			socketsByID.set(id, this);

			if (maxQueuedBytes != DEFAULT_MAX_QUEUED) NativeCFFI.lime_local_socket_set_max_queued(handle, maxQueuedBytes);
		}
		#end
	}
}
