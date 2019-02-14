package flash.filesystem;

@:final extern class StorageVolumeInfo extends flash.events.EventDispatcher
{
	function new():Void;
	function getStorageVolumes():flash.Vector<StorageVolume>;
	static var isSupported(default, never):Bool;
	static var storageVolumeInfo(default, never):StorageVolumeInfo;
}
