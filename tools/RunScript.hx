package;

import hxp.*;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class RunScript
{
	private static function rebuildTools(toolsDirectory:String, targetDirectory:String = null, rebuildBinaries = true):Void
	{
		if (targetDirectory == null)
		{
			targetDirectory = toolsDirectory;
		}

		Haxelib.workingDirectory = targetDirectory;

		/*var extendedToolsDirectory = Haxelib.getPath (new Haxelib ("lime-extended"), false);

			if (extendedToolsDirectory != null && extendedToolsDirectory != "") {

				var buildScript = File.getContent (Path.combine (extendedToolsDirectory, "tools.hxml"));
				buildScript = StringTools.replace (buildScript, "\r\n", "\n");
				buildScript = StringTools.replace (buildScript, "\n", " ");

				System.runCommand (toolsDirectory, "haxe", buildScript.split (" "));

		} else {*/

		HXML.buildFile(toolsDirectory + "/tools.hxml", targetDirectory);

		// }

		if (!rebuildBinaries) return;

		var platforms = ["Windows", "Mac", "Mac64", "Linux", "Linux64"];

		for (platform in platforms)
		{
			var source = Path.combine(targetDirectory, "ndll/" + platform + "/lime.ndll");
			// var target = Path.combine (toolsDirectory, "ndll/" + platform + "/lime.ndll");

			if (!FileSystem.exists(source))
			{
				var args = [Path.combine(targetDirectory, "tools.n"), "rebuild", "lime", "-release", "-nocffi"];

				if (Log.verbose)
				{
					args.push("-verbose");
				}

				if (!Log.enableColor)
				{
					args.push("-nocolor");
				}

				switch (platform)
				{
					case "Windows":
						if (System.hostPlatform == WINDOWS)
						{
							System.runCommand(targetDirectory, "neko", args.concat(["windows", targetDirectory]));
						}

					case "Mac", "Mac64":
						if (System.hostPlatform == MAC)
						{
							System.runCommand(targetDirectory, "neko", args.concat(["mac", targetDirectory]));
						}

					case "Linux":
						if (System.hostPlatform == LINUX && System.hostArchitecture != X64)
						{
							System.runCommand(targetDirectory, "neko", args.concat(["linux", "-32", targetDirectory]));
						}

					case "Linux64":
						if (System.hostPlatform == LINUX && System.hostArchitecture == X64)
						{
							System.runCommand(targetDirectory, "neko", args.concat(["linux", "-64", targetDirectory]));
						}
				}
			}

			if (!FileSystem.exists(source))
			{
				if (Log.verbose)
				{
					Log.warn("", "Source path \"" + source + "\" does not exist");
				}
			}
			else
			{
				// System.copyIfNewer (source, target);
			}
		}
	}

	public static function runCommand(path:String, command:String, args:Array<String>, throwErrors:Bool = true):Int
	{
		var oldPath:String = "";

		if (path != null && path != "")
		{
			oldPath = Sys.getCwd();

			try
			{
				Sys.setCwd(path);
			}
			catch (e:Dynamic)
			{
				Log.error("Cannot set current working directory to \"" + path + "\"");
			}
		}

		var result:Dynamic = Sys.command(command, args);

		if (oldPath != "")
		{
			Sys.setCwd(oldPath);
		}

		if (throwErrors && result != 0)
		{
			Sys.exit(1);
		}

		return result;
	}

	public static function main()
	{
		var args = Sys.args();

		var cacheDirectory = Sys.getCwd();

		if (args.length > 0)
		{
			var lastArgument = new Path(args[args.length - 1]).toString();

			if (((StringTools.endsWith(lastArgument, "/") && lastArgument != "/") || StringTools.endsWith(lastArgument, "\\"))
				&& !StringTools.endsWith(lastArgument, ":\\"))
			{
				lastArgument = lastArgument.substr(0, lastArgument.length - 1);
			}

			if (FileSystem.exists(lastArgument) && FileSystem.isDirectory(lastArgument))
			{
				Sys.setCwd(lastArgument);
			}
		}

		var workingDirectory = Sys.getCwd();

		if (args.length > 2 && args[0] == "rebuild" && args[1] == "tools")
		{
			var rebuildBinaries = true;

			for (arg in args)
			{
				var equals = arg.indexOf("=");

				if (equals > -1 && StringTools.startsWith(arg, "--"))
				{
					var argValue = arg.substr(equals + 1);
					var field = arg.substr(2, equals - 2);

					if (StringTools.startsWith(field, "haxelib-"))
					{
						var name = field.substr(8);
						Haxelib.pathOverrides.set(name, Path.tryFullPath(argValue));
					}
				}
				else if (StringTools.startsWith(arg, "-"))
				{
					switch (arg)
					{
						case "-v", "-verbose":
							Log.verbose = true;

						case "-nocolor":
							Log.enableColor = false;

						case "-nocffi":
							rebuildBinaries = false;

						default:
					}
				}
			}

			rebuildTools(workingDirectory, rebuildBinaries);

			if (args.indexOf("-openfl") > -1)
			{
				Sys.setCwd(cacheDirectory);
			}
			else
			{
				Sys.exit(0);
			}
		}
		else if (args.length > 1 && args[0] == "scope")
		{
			switch args[1]
			{
				case "create":
					System.makeDirectory(".lime");

				case "delete":
					System.removeDirectory(".lime");

				default:
					Log.error("Incorrect arguments for command 'scope'");
			}

			return;
		}

		var toolsPath:String = checkTools(workingDirectory, args);
		var args = [Path.withoutDirectory(toolsPath)].concat(args);
		Sys.exit(runCommand(Path.directory(toolsPath), "neko", args));

	}

	private static function checkTools(workingDirectory:String, args:Array<String>):String
	{
		var scopeDirectory:String = workingDirectory + "/.lime";
		var toolsDirectory:String = Path.combine(Haxelib.getPath(new Haxelib("lime"), true), "tools");

		if (!FileSystem.exists(toolsDirectory))
		{
			toolsDirectory = Path.combine(toolsDirectory, "../../tools");
		}

		if (FileSystem.exists(scopeDirectory) && FileSystem.isDirectory(scopeDirectory))
		{
			if (!hasTools(scopeDirectory) || args.indexOf("-rebuild") > -1)
			{
				rebuildTools(toolsDirectory, scopeDirectory);
			}

			return scopeDirectory + "/tools.n";
		}
		else
		{
			if (!hasTools(toolsDirectory) || args.indexOf("-rebuild") > -1)
			{
				rebuildTools(toolsDirectory);
			}

			return toolsDirectory + "/tools.n";
		}
	}

	private static function hasTools(directory:String):Bool
	{
		return FileSystem.exists(directory + "/tools.n");
	}
}
