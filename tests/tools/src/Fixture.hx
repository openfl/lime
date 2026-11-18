import haxe.PosInfos;
import hxp.Haxelib;
import hxp.Path;
import hxp.System;
import lime.tools.Asset;
import lime.tools.HXProject;
import lime.tools.Platform;
import lime.tools.ProjectXMLParser;
import sys.FileSystem;
import sys.io.File;
import utest.Assert;

/**
	A project folder in the system's temporary directory. Tests write project files and
	assets into it, then parse them the way `lime` does: from inside the folder, by name.

	Fixture XML is written in single-quoted strings, where `$$` is a literal `$`, so
	`$${meta.title}` reaches the parser as `${meta.title}`.
**/
class Fixture
{
	private static var nextID = 0;

	public var command:String;
	public var debug:Bool;

	/**
		The defines given on the command line, such as `-Dblue`.
	**/
	public var defines:Map<String, Dynamic>;

	public var directory(default, null):String;
	public var includePaths:Array<String>;
	public var target:Platform;
	public var targetFlags:Map<String, String>;

	private var previousOverrides:Array<String>;

	public function new()
	{
		var temp = Sys.getEnv(Sys.systemName() == "Windows" ? "TEMP" : "TMPDIR");
		if (temp == null || temp == "") temp = "/tmp";

		directory = Path.combine(Path.standardize(temp), "lime-tools-test-" + Std.random(0x3FFFFFFF) + "-" + (nextID++));
		FileSystem.createDirectory(directory);

		command = "build";
		debug = false;
		defines = new Map();
		includePaths = [];
		target = System.hostPlatform;
		targetFlags = new Map();

		previousOverrides = [for (name in Haxelib.pathOverrides.keys()) name];
	}

	/**
		Adds a haxelib that `<haxelib name="..." />` finds without running `haxelib`,
		with an `include.xml` and any other files it needs. Returns its folder.
	**/
	public function addHaxelib(name:String, includeXML:String, files:Map<String, String> = null):String
	{
		var path = Path.combine(directory, "haxelib/" + name);

		write("haxelib/" + name + "/haxelib.json", '{"name": "$name", "version": "1.0.0"}');
		write("haxelib/" + name + "/include.xml", includeXML);

		if (files != null)
		{
			for (file in files.keys())
			{
				write("haxelib/" + name + "/" + file, files.get(file));
			}
		}

		Haxelib.pathOverrides.set(name, path);
		return path;
	}

	public function dispose():Void
	{
		for (name in [for (key in Haxelib.pathOverrides.keys()) key])
		{
			if (previousOverrides.indexOf(name) == -1)
			{
				Haxelib.pathOverrides.remove(name);
			}
		}

		removeDirectory(directory);
	}

	/**
		Reads a project file the fixture already holds.
	**/
	public function load(file:String = "project.xml"):ProjectXMLParser
	{
		prepare();

		var cwd = Sys.getCwd();
		Sys.setCwd(directory);

		var project:ProjectXMLParser = null;

		try
		{
			project = new ProjectXMLParser(file, defines, includePaths);
		}
		catch (e:Dynamic)
		{
			Sys.setCwd(cwd);
			throw e;
		}

		Sys.setCwd(cwd);
		return project;
	}

	/**
		Writes a project file and reads it.
	**/
	public function parse(xml:String, file:String = "project.xml"):ProjectXMLParser
	{
		write(file, xml);
		return load(file);
	}

	/**
		Sets what `lime` sets before it reads a project, so a new `HXProject` matches it.
	**/
	public function prepare():Void
	{
		HXProject._command = command;
		HXProject._debug = debug;
		HXProject._environment = new Map();
		HXProject._projectFilePath = null;
		HXProject._target = target;
		HXProject._targetFlags = targetFlags;
		HXProject._templatePaths = [];
		HXProject._userDefines = null;
	}

	/**
		Writes a file under the fixture's folder, and returns its full path.
	**/
	public function write(path:String, content:String):String
	{
		var fullPath = Path.combine(directory, path);
		FileSystem.createDirectory(Path.directory(fullPath));
		File.saveContent(fullPath, content);
		return fullPath;
	}

	/**
		`Assert.same()`, saying what was found when they differ.
	**/
	public static function assertSame(expected:Dynamic, actual:Dynamic, ?pos:PosInfos):Bool
	{
		return Assert.same(expected, actual, true, "expected " + Std.string(expected) + " but it is " + Std.string(actual), null, pos);
	}

	public static function countAssets(project:HXProject, targetPath:String):Int
	{
		var count = 0;

		for (asset in project.assets)
		{
			if (asset.targetPath == targetPath) count++;
		}

		return count;
	}

	public static function findAsset(project:HXProject, targetPath:String):Asset
	{
		for (asset in project.assets)
		{
			if (asset.targetPath == targetPath) return asset;
		}

		return null;
	}

	public static function hasKey(pairs:Array<{key:String, value:Dynamic}>, key:String):Bool
	{
		for (pair in pairs)
		{
			if (pair.key == key) return true;
		}

		return false;
	}

	/**
		The target paths of a project's assets, sorted.
	**/
	public static function targetPaths(project:HXProject):Array<String>
	{
		var paths = [for (asset in project.assets) asset.targetPath];
		paths.sort(Reflect.compare);
		return paths;
	}

	public static function valueOf(pairs:Array<{key:String, value:Dynamic}>, key:String):Dynamic
	{
		for (pair in pairs)
		{
			if (pair.key == key) return pair.value;
		}

		return null;
	}

	private static function removeDirectory(path:String):Void
	{
		if (!FileSystem.exists(path)) return;

		for (file in FileSystem.readDirectory(path))
		{
			var child = path + "/" + file;

			if (FileSystem.isDirectory(child))
			{
				removeDirectory(child);
			}
			else
			{
				FileSystem.deleteFile(child);
			}
		}

		FileSystem.deleteDirectory(path);
	}
}
