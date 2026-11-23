package utils;

#if sys
import haxe.Timer;
import haxe.io.Bytes;
import haxe.io.Path;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import sys.FileSystem;
import sys.io.File;

/**
	Files the asset tests write, in a directory of their own under the system's
	temporary directory, which `remove()` deletes again.
**/
class AssetTestFiles
{
	public var directory(default, null):String;

	public function new(name:String)
	{
		var temp = Sys.getEnv("TEMP");
		if (temp == null || temp == "") temp = Sys.getEnv("TMPDIR");
		if (temp == null || temp == "") temp = "/tmp";

		directory = Path.removeTrailingSlashes(Path.normalize(temp)) + "/lime-" + name + "-" + Std.int(Timer.stamp() * 1000) + "-" + Std.random(1000000);
		FileSystem.createDirectory(directory);
	}

	public function path(name:String):String
	{
		return directory + "/" + name;
	}

	public function write(name:String, bytes:Bytes):String
	{
		var path = path(name);
		FileSystem.createDirectory(Path.directory(path));
		File.saveBytes(path, bytes);
		return path;
	}

	public function writeText(name:String, text:String):String
	{
		return write(name, Bytes.ofString(text));
	}

	public function copy(source:String, name:String):String
	{
		return write(name, File.getBytes(source));
	}

	public function delete(name:String):Void
	{
		if (FileSystem.exists(path(name))) FileSystem.deleteFile(path(name));
	}

	public function remove():Void
	{
		// Fonts read from a file keep it open until they are collected
		collect();
		collect();
		removeDirectory(directory);
	}

	public static function manifest(rootPath:String, assets:Array<Dynamic>):AssetManifest
	{
		var manifest = new AssetManifest();
		manifest.rootPath = rootPath;
		manifest.assets = assets;
		return manifest;
	}

	public static function library(rootPath:String, assets:Array<Dynamic>):AssetLibrary
	{
		return AssetLibrary.fromManifest(manifest(rootPath, assets));
	}

	// Byte by byte, as Md5.make() on Neko hashes the whole buffer behind Bytes from native code
	public static function sameBytes(expected:Bytes, actual:Bytes):Bool
	{
		if (expected == null || actual == null) return expected == actual;
		if (expected.length != actual.length) return false;

		for (i in 0...expected.length)
		{
			if (expected.get(i) != actual.get(i)) return false;
		}

		return true;
	}

	private static function collect():Void
	{
		#if cpp
		cpp.vm.Gc.run(true);
		#elseif neko
		neko.vm.Gc.run(true);
		#elseif hl
		hl.Gc.major();
		#end
	}

	private static function removeDirectory(path:String):Void
	{
		if (!FileSystem.exists(path)) return;

		for (name in FileSystem.readDirectory(path))
		{
			var child = path + "/" + name;

			if (FileSystem.isDirectory(child))
			{
				removeDirectory(child);
			}
			else
			{
				try
				{
					FileSystem.deleteFile(child);
				}
				catch (e:Dynamic) {}
			}
		}

		try
		{
			FileSystem.deleteDirectory(path);
		}
		catch (e:Dynamic) {}
	}
}
#end
