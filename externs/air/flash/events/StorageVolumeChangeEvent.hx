package flash.events;

extern class StorageVolumeChangeEvent extends Event
{
	var _rootDirectory:flash.filesystem.File;
	var _volume:flash.filesystem.StorageVolume;
	var rootDirectory(default, never):flash.filesystem.File;
	var storageVolume(default, never):flash.filesystem.StorageVolume;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, ?path:flash.filesystem.File, ?volume:flash.filesystem.StorageVolume):Void;
	static var STORAGE_VOLUME_MOUNT(default, never):String;
	static var STORAGE_VOLUME_UNMOUNT(default, never):String;
}
