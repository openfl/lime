package lime.system;

import haxe.Timer;
import lime._internal.backend.native.NativeCFFI;
import lime.app.Event;
import lime.app.Future;

/**
	A mounted drive, partition or network share, and the events for volumes
	mounting and unmounting, as a USB drive is plugged in or ejected.

	Once `onMount` or `onUnmount` is first used, the volumes are compared
	once a second, on a background thread where there is one, as a network
	drive can take a moment to answer.

	Available on Windows, macOS and Linux. On Linux the volumes are the
	mounted block devices, and network shares are not listed.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class StorageVolume
{
	private static inline var POLL_MS:Int = 1000;

	/**
		Whether the volumes can be listed on this platform.
	**/
	public static var isSupported(get, never):Bool;

	/**
		Dispatched with a volume that has just mounted.
	**/
	public static var onMount(get, never):Event<StorageVolume->Void>;

	/**
		Dispatched with a volume that has just unmounted. It is the volume as it
		was listed, as it can no longer be read.
	**/
	public static var onUnmount(get, never):Event<StorageVolume->Void>;

	/**
		The drive letter on Windows, as `"C"`, and `null` elsewhere.
	**/
	public var drive(default, null):String;

	/**
		The volume's file system, as `"NTFS"`, `"apfs"` or `"ext4"`.
	**/
	public var fileSystemType(default, null):String;

	/**
		Whether the volume can be removed, as a USB drive, memory card or
		optical disc can.
	**/
	public var isRemovable(default, null):Bool;

	/**
		Whether files can be written to the volume.
	**/
	public var isWritable(default, null):Bool;

	/**
		The volume's label, or its drive or mount point when it has none.
	**/
	public var name(default, null):String;

	/**
		The folder the volume's files start in, as `C:\` or `/media/user/USB`.
	**/
	public var rootDirectory(default, null):String;

	@:noCompletion private static var __known:Map<String, StorageVolume>;
	@:noCompletion private static var __mount:Event<StorageVolume->Void>;
	@:noCompletion private static var __polling:Bool = false;
	@:noCompletion private static var __timer:Timer;
	@:noCompletion private static var __unmount:Event<StorageVolume->Void>;

	@:noCompletion private function new() {}

	/**
		The volumes mounted now, or an empty array where they cannot be
		listed.
	**/
	public static function getVolumes():Array<StorageVolume>
	{
		var volumes = __read();
		return volumes != null ? volumes : [];
	}

	@:noCompletion private static function __read():Array<StorageVolume>
	{
		#if (lime_cffi && !macro)
		var text:String = CFFI.stringValue(NativeCFFI.lime_system_get_storage_volumes());
		if (text == null) return null;

		var volumes = [];

		for (record in text.split("\x1E"))
		{
			var fields = record.split("\x1F");
			if (fields.length < 6) continue;

			var volume = new StorageVolume();
			volume.rootDirectory = fields[0];
			volume.name = fields[1];
			volume.fileSystemType = fields[2];
			volume.drive = fields[3] != "" ? fields[3] : null;
			volume.isRemovable = fields[4] == "1";
			volume.isWritable = fields[5] == "1";
			volumes.push(volume);
		}

		return volumes;
		#else
		return null;
		#end
	}

	@:noCompletion private static function __compare(volumes:Array<StorageVolume>):Void
	{
		if (volumes == null) return;

		var current = new Map<String, StorageVolume>();
		for (volume in volumes) current.set(volume.rootDirectory, volume);

		var previous = __known;
		__known = current;

		// The first list is what was mounted already
		if (previous == null) return;

		for (root in previous.keys())
		{
			if (!current.exists(root)) __unmount.dispatch(previous.get(root));
		}

		for (root in current.keys())
		{
			if (!previous.exists(root)) __mount.dispatch(current.get(root));
		}
	}

	@:noCompletion private static function __poll():Void
	{
		if (__polling) return;
		__polling = true;

		#if (lime_threads && !html5)
		new Future<Array<StorageVolume>>(__read, true).onComplete(function(volumes)
		{
			__polling = false;
			__compare(volumes);
		}).onError(function(_) __polling = false);
		#else
		__compare(__read());
		__polling = false;
		#end
	}

	@:noCompletion private static function __watch():Void
	{
		if (__mount == null)
		{
			__mount = new Event<StorageVolume->Void>();
			__unmount = new Event<StorageVolume->Void>();
		}

		if (__timer == null && get_isSupported())
		{
			__poll();
			__timer = new Timer(POLL_MS);
			__timer.run = __poll;
		}
	}

	// Get & Set Methods
	@:noCompletion private static function get_isSupported():Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_system_get_storage_volumes() != null;
		#else
		return false;
		#end
	}

	@:noCompletion private static function get_onMount():Event<StorageVolume->Void>
	{
		__watch();
		return __mount;
	}

	@:noCompletion private static function get_onUnmount():Event<StorageVolume->Void>
	{
		__watch();
		return __unmount;
	}
}
