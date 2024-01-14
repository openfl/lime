package sys;

import flash.filesystem.File in FlashFile;
import lime.utils.Log;

@:dce
@:coreApi
class FileSystem
{
	public static function exists(path:String):Bool
	{
		return new FlashFile(path).exists;
	}

	public static function rename(path:String, newPath:String):Void
	{
		new FlashFile(path).moveTo(new FlashFile(newPath));
	}

	public static function stat(path:String):sys.FileStat
	{
		Log.warn("stat is not implemented");
		return null;
	}

	public static function fullPath(relPath:String):String
	{
		var flashFile = new FlashFile(relPath);
		flashFile.canonicalize();
		return flashFile.nativePath;
	}

	public static function absolutePath(relPath:String):String
	{
		return new FlashFile(relPath).nativePath;
	}

	public static function isDirectory(path:String):Bool
	{
		return new FlashFile(path).isDirectory;
	}

	public static function createDirectory(path:String):Void
	{
		new FlashFile(path).createDirectory();
	}

	public static function deleteFile(path:String):Void
	{
		new FlashFile(path).deleteFile();
	}

	public static function deleteDirectory(path:String):Void
	{
		new FlashFile(path).deleteDirectory(false);
	}

	public static function readDirectory(path:String):Array<String>
	{
		return new FlashFile(path).getDirectoryListing().map(function(f:FlashFile):String
		{
			return f.name;
		});
	}
}
