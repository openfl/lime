package;

import hxp.*;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class RunScript
{
	private static function rebuildTools(rebuildBinaries = true):Void
	{
		var limeDirectory = Haxelib.getPath(new Haxelib("lime"), true);
		var toolsDirectory = Path.combine(limeDirectory, "tools");

		if (!FileSystem.exists(toolsDirectory))
		{
			toolsDirectory = Path.combine(limeDirectory, "../tools");
		}

		/*var extendedToolsDirectory = Haxelib.getPath (new Haxelib ("lime-extended"), false);

			if (extendedToolsDirectory != null && extendedToolsDirectory != "") {

				var buildScript = File.getContent (Path.combine (extendedToolsDirectory, "tools.hxml"));
				buildScript = StringTools.replace (buildScript, "\r\n", "\n");
				buildScript = StringTools.replace (buildScript, "\n", " ");

				System.runCommand (toolsDirectory, "haxe", buildScript.split (" "));

		} else {*/

		System.runCommand(toolsDirectory, "haxe", ["tools.hxml"]);

		// }

		if (!rebuildBinaries) return;

		var platforms = ["Windows", "Mac", "Mac64", "Linux", "Linux64"];

		for (platform in platforms)
		{
			var source = Path.combine(limeDirectory, "ndll/" + platform + "/lime.ndll");
			// var target = Path.combine (toolsDirectory, "ndll/" + platform + "/lime.ndll");

			if (!FileSystem.exists(source))
			{
				var args = ["tools/tools.n", "rebuild", "lime", "-release", "-nocffi"];

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
							System.runCommand(limeDirectory, "neko", args.concat(["windows", toolsDirectory]));
						}

					case "Mac", "Mac64":
						if (System.hostPlatform == MAC)
						{
							System.runCommand(limeDirectory, "neko", args.concat(["mac", toolsDirectory]));
						}

					case "Linux":
						if (System.hostPlatform == LINUX && System.hostArchitecture != X64)
						{
							System.runCommand(limeDirectory, "neko", args.concat(["linux", "-32", toolsDirectory]));
						}

					case "Linux64":
						if (System.hostPlatform == LINUX && System.hostArchitecture == X64)
						{
							System.runCommand(limeDirectory, "neko", args.concat(["linux", "-64", toolsDirectory]));
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

		if (args.length > 2 && args[0] == "rebuild" && args[1] == "tools")
		{
			var lastArgument = new Path(args[args.length - 1]).toString();
			var cacheDirectory = Sys.getCwd();

			if (((StringTools.endsWith(lastArgument, "/") && lastArgument != "/") || StringTools.endsWith(lastArgument, "\\"))
				&& !StringTools.endsWith(lastArgument, ":\\"))
			{
				lastArgument = lastArgument.substr(0, lastArgument.length - 1);
			}

			if (FileSystem.exists(lastArgument) && FileSystem.isDirectory(lastArgument))
			{
				Sys.setCwd(lastArgument);
			}

			Haxelib.workingDirectory = Sys.getCwd();
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

			rebuildTools(rebuildBinaries);

			if (args.indexOf("-openfl") > -1)
			{
				Sys.setCwd(cacheDirectory);
			}
			else
			{
				Sys.exit(0);
			}
		}

		if (!FileSystem.exists("tools/tools.n") || args.indexOf("-rebuild") > -1)
		{
			rebuildTools();
		}

		var args = ["tools/tools.n"].concat(args);
		Sys.exit(runCommand("", "neko", args));
	}
}
