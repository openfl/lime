package flash.filesystem;

extern class File extends flash.net.FileReference
{
	var downloaded:Bool;
	var exists(default, never):Bool;
	var icon(default, never):flash.desktop.Icon;
	var isDirectory(default, never):Bool;
	var isHidden(default, never):Bool;
	var isPackage(default, never):Bool;
	var isSymbolicLink(default, never):Bool;
	var nativePath:String;
	var parent(default, never):File;
	var preventBackup:Bool;
	var spaceAvailable(default, never):Float;
	var url:String;
	function new(?path:String):Void;
	function browseForDirectory(title:String):Void;
	function browseForOpen(title:String, ?typeFilter:Array<flash.net.FileFilter>):Void;
	function browseForOpenMultiple(title:String, ?typeFilter:Array<flash.net.FileFilter>):Void;
	function browseForSave(title:String):Void;
	function canonicalize():Void;
	function clone():File;
	function copyTo(newLocation:flash.net.FileReference, overwrite:Bool = false):Void;
	function copyToAsync(newLocation:flash.net.FileReference, overwrite:Bool = false):Void;
	function createDirectory():Void;
	function deleteDirectory(deleteDirectoryContents:Bool = false):Void;
	function deleteDirectoryAsync(deleteDirectoryContents:Bool = false):Void;
	function deleteFile():Void;
	function deleteFileAsync():Void;
	function getDirectoryListing():Array<File>;
	function getDirectoryListingAsync():Void;
	function getRelativePath(ref:flash.net.FileReference, useDotDot:Bool = false):String;
	function moveTo(newLocation:flash.net.FileReference, overwrite:Bool = false):Void;
	function moveToAsync(newLocation:flash.net.FileReference, overwrite:Bool = false):Void;
	function moveToTrash():Void;
	function moveToTrashAsync():Void;
	function openWithDefaultApplication():Void;
	function resolvePath(path:String):File;
	static var applicationDirectory(default, never):File;
	static var applicationStorageDirectory(default, never):File;
	static var cacheDirectory(default, never):File;
	static var desktopDirectory(default, never):File;
	static var documentsDirectory(default, never):File;
	static var lineEnding(default, never):String;
	static var permissionStatus(default, never):String;
	static var separator(default, never):String;
	static var systemCharset(default, never):String;
	static var userDirectory(default, never):File;
	static function createTempDirectory():File;
	static function createTempFile():File;
	static function getRootDirectories():Array<File>;
}
