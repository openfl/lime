package sys.io;

import openfl.utils.ByteArray;
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

	public static function saveContent(path:String, content:String):Void
	{
		var file = new FlashFile(path);
		var stream = new FileStream();
		stream.open(file, FileMode.WRITE);
		stream.writeUTFBytes(content);
		stream.close();
	}

	public static function getBytes(path:String):haxe.io.Bytes
	{
		var file = new FlashFile(path);
		var stream = new FileStream();
		stream.open(file, FileMode.READ);
		var byteArray = new ByteArray();
		stream.readBytes(byteArray, 0, stream.bytesAvailable);
		stream.close();
		var bytes:haxe.io.Bytes = byteArray;
		return bytes;
	}

	public static function saveBytes(path:String, bytes:haxe.io.Bytes):Void
	{
		var byteArray:ByteArray = bytes;
		var file = new FlashFile(path);
		var stream = new FileStream();
		stream.open(file, FileMode.WRITE);
		stream.writeBytes(byteArray);
		stream.close();
	}

	public static function read(path:String, binary:Bool = true):FileInput
	{
		openfl.Lib.notImplemented();
		return null;
	}

	public static function write(path:String, binary:Bool = true):FileOutput
	{
		openfl.Lib.notImplemented();
		return null;
	}

	public static function append(path:String, binary:Bool = true):FileOutput
	{
		openfl.Lib.notImplemented();
		return null;
	}

	public static function update(path:String, binary:Bool = true):FileOutput
	{
		openfl.Lib.notImplemented();
		return null;
	}

	public static function copy(srcPath:String, dstPath:String):Void
	{
		new FlashFile(srcPath).copyTo(new FlashFile(dstPath));
	}
}
