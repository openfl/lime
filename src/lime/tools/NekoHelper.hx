package lime.tools;

import hxp.*;
import lime.tools.Platform;
import sys.FileSystem;
import sys.io.File;

class NekoHelper
{
	public static function copyLibraries(templatePaths:Array<String>, platformName:String, targetPath:String)
	{
		// System.recursiveCopyTemplate (templatePaths, "neko/ndll/" + platformName, targetPath);
	}

	public static function createExecutable(templatePaths:Array<String>, platformName:String, source:String, target:String, iconPath:String = null):Void
	{
		/*var executablePath = System.findTemplate (templatePaths, "neko/bin/neko-" + platformName);
			var executable = File.getBytes (executablePath);
			var sourceContents = File.getBytes (source);

			var output = File.write (target, true);
			output.write (executable);
			output.write (sourceContents);
			output.writeString ("NEKO");
			output.writeInt32 (executable.length);
			output.close (); */

		var path = Path.tryFullPath(source);
		var file = Path.withoutDirectory(path);
		var dir = Path.directory(path);

		System.runCommand(dir, "nekotools", ["boot", file]);

		var path = Path.withoutExtension(source);

		if (System.hostPlatform == WINDOWS)
		{
			path += ".exe";
		}

		System.copyFile(path, target);
	}

	public static function createWindowsExecutable(templatePaths:Array<String>, source:String, target:String, iconPath:String):Void
	{
		/*var executablePath = System.findTemplate (templatePaths, "neko/bin/neko-windows");
			var executable = File.getBytes (executablePath);
			var sourceContents = File.getBytes (source);

			var output = File.write (target, true);
			output.write (executable);
			output.close ();

			if (iconPath != null && System.hostPlatform == WINDOWS) {

				var templates = [ Haxelib.getPath (new Haxelib (#if lime "lime" #else "hxp" #end)) + "/templates" ].concat (templatePaths);
				System.runCommand ("", System.findTemplate (templates, "bin/ReplaceVistaIcon.exe"), [ target, iconPath, "1" ], true, true);

			}

			var executable = File.getBytes (target);
			var output = File.write (target, true);
			output.write (executable);
			output.write (sourceContents);
			output.writeString ("NEKO");
			output.writeInt32 (executable.length);
			output.close (); */

		createExecutable(templatePaths, null, source, target, iconPath);
	}
}
