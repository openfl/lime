package flash.filesystem;

extern class StorageVolume
{
	var drive(default, never):String;
	var fileSystemType(default, never):String;
	var isRemovable(default, never):Bool;
	var isWritable(default, never):Bool;
	var name(default, never):String;
	var rootDirectory(default, never):File;
	function new(rootDirPath:File, name:String, writable:Bool, removable:Bool, fileSysType:String, drive:String):Void;
}
