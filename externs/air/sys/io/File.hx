package sys.io;

import flash.filesystem.File in FlashFile;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

@:dce
@:coreApi
class File
{
	public static function getContent(path:String):String
	{
		var file = new FlashFile(path);
		var stream = new FileStream();
		stream.open(file, FileMode.READ);
		var content = stream.readUTFBytes(stream.bytesAvailable);
		stream.close();
		return content;
	}

	public static function saveContent(path:String, content:String):Void {}

	public static function getBytes(path:String):haxe.io.Bytes
	{
		return null;
	}

	public static function saveBytes(path:String, bytes:haxe.io.Bytes):Void {}

	public static function read(path:String, binary:Bool = true):FileInput
	{
		return null;
	}

	public static function write(path:String, binary:Bool = true):FileOutput
	{
		return null;
	}

	public static function append(path:String, binary:Bool = true):FileOutput
	{
		return null;
	}

	public static function update(path:String, binary:Bool = true):FileOutput
	{
		return null;
	}

	public static function copy(srcPath:String, dstPath:String):Void {}
}
