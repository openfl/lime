package sys;

@:dce
@:coreApi
class FileSystem
{
	public static function exists(path:String):Bool
	{
		return false;
	}

	public static function rename(path:String, newPath:String):Void {}

	public static function stat(path:String):sys.FileStat
	{
		return null;
	}

	public static function fullPath(relPath:String):String
	{
		return null;
	}

	public static function absolutePath(relPath:String):String
	{
		return null;
	}

	public static function isDirectory(path:String):Bool
	{
		return false;
	}

	public static function createDirectory(path:String):Void {}

	public static function deleteFile(path:String):Void {}

	public static function deleteDirectory(path:String):Void {}

	public static function readDirectory(path:String):Array<String> {}
}
