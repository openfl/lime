package utils;

import haxe.Json;
import hxp.*;
import lime.tools.HXProject;
import lime.tools.NativeSourcesHelper;
import lime.tools.Platform;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

/**
	Checks of the haxelibs and tools a native build runs on, and the report `lime diagnose`
	prints for bug reports.
**/
class BuildEnvironment
{
	private static var checkedHxcpp = false;

	/**
		Warns, once, when `-lib hxcpp` is not libhxcpp where that is a setup mistake: Lime is a
		git checkout, which is built and tested with libhxcpp, or libhxcpp is installed but
		`haxelib run libhxcpp setup` has not pointed hxcpp at it.
	**/
	public static function checkHxcpp():Void
	{
		if (checkedHxcpp) return;
		checkedHxcpp = true;

		var hxcppPath = Haxelib.getPath(new Haxelib("hxcpp"));
		if (hxcppPath == null || hxcppPath == "" || getHaxelibName(hxcppPath) == "libhxcpp") return;

		var limePath = Haxelib.getPath(new Haxelib("lime"));
		var libhxcppPath = Haxelib.getPath(new Haxelib("libhxcpp"));
		var message = getHxcppWarning(hxcppPath, NativeSourcesHelper.isGitCheckout(limePath), libhxcppPath);

		if (message != null)
		{
			Log.warn(message);
		}
	}

	/**
		The warning for an hxcpp haxelib in `hxcppPath`, or `null` when there is nothing to say.
		`libhxcppPath` is where libhxcpp is installed, or `null` or "" when it is not.
	**/
	public static function getHxcppWarning(hxcppPath:String, limeIsGitCheckout:Bool, libhxcppPath:String):String
	{
		if (hxcppPath == null || hxcppPath == "") return null;

		var name = getHaxelibName(hxcppPath);
		if (name == "libhxcpp") return null;

		var description = (name != null ? name : "hxcpp");
		var version = getHaxelibVersion(hxcppPath);
		if (version != null) description += " " + version;
		description += " in " + Path.standardize(hxcppPath, false);

		if (libhxcppPath != null && libhxcppPath != "")
		{
			return "The hxcpp haxelib is "
				+ description
				+ ", not the libhxcpp installed in "
				+ Path.standardize(libhxcppPath, false)
				+ ", so C++ builds do not use libhxcpp, which Lime is built and tested with. They can fail or crash in ways that are hard to trace. To point hxcpp at libhxcpp, run: haxelib run libhxcpp setup";
		}
		else if (limeIsGitCheckout)
		{
			return "The hxcpp haxelib is "
				+ description
				+ ", and Lime from git is built and tested with libhxcpp, the continuation of hxcpp. With another hxcpp, C++ builds can fail or crash in ways that are hard to trace. To install libhxcpp and point hxcpp at it, run: haxelib git libhxcpp https://github.com/openfl/libhxcpp, then: haxelib run libhxcpp setup";
		}

		return null;
	}

	/**
		Whether a build or rebuild for `project` compiles with hxcpp.
	**/
	public static function usesHxcpp(project:HXProject, rebuild:Bool = false):Bool
	{
		var flags = project.targetFlags;

		return switch (project.target)
		{
			case WINDOWS, MAC, LINUX:
				// A rebuild compiles the native libraries for Neko and HashLink too
				rebuild || !(flags.exists("neko") || flags.exists("hl") || flags.exists("java") || flags.exists("nodejs") || flags.exists("cs")
					|| flags.exists("winjs"));
			case ANDROID, IOS, TVOS, WEB_ASSEMBLY, EMSCRIPTEN:
				true;
			default:
				false;
		}
	}

	/**
		The `name` in a haxelib's haxelib.json, or `null`.
	**/
	public static function getHaxelibName(path:String):String
	{
		var json = readHaxelibJson(path);
		return (json != null && json.name != null) ? Std.string(json.name) : null;
	}

	/**
		The `version` in a haxelib's haxelib.json, or `null`.
	**/
	public static function getHaxelibVersion(path:String):String
	{
		var json = readHaxelibJson(path);
		return (json != null && json.version != null) ? Std.string(json.version) : null;
	}

	/**
		Prints what `lime diagnose` shows: the versions and setup a bug report about a native
		build needs, as plain text.
	**/
	public static function printReport():Void
	{
		for (line in getReport())
		{
			Sys.println(line);
		}
	}

	public static function getReport():Array<String>
	{
		var lines = [];

		lines.push("Host: " + getHostDescription());
		lines.push("Haxe: " + getHaxeVersion());

		var limePath = Haxelib.getPath(new Haxelib("lime"));
		lines.push("Lime: " + describeHaxelib(limePath));
		lines.push("OpenFL: " + describeHaxelib(Haxelib.getPath(new Haxelib("openfl"))));
		lines.push("libhxcpp: " + describeHaxelib(Haxelib.getPath(new Haxelib("libhxcpp"))));

		var hxcppPath = Haxelib.getPath(new Haxelib("hxcpp"));
		var hxcppLine = "hxcpp (haxelib path hxcpp): ";

		if (hxcppPath == null || hxcppPath == "")
		{
			hxcppLine += "not installed";
		}
		else
		{
			var name = getHaxelibName(hxcppPath);
			hxcppLine += (name != null ? name + " " : "") + describeHaxelib(hxcppPath);
		}

		lines.push(hxcppLine);
		lines.push("C++ compiler: " + getCompilerDescription(hxcppPath));

		if (limePath != null && limePath != "")
		{
			var root = Path.standardize(limePath, false);

			if (NativeSourcesHelper.isGitCheckout(root))
			{
				lines.push("Lime submodules: " + describeSubmodules(root));
			}

			lines.push("Lime native libraries:");

			var libraries = describeLibraries(root);

			if (libraries.length == 0)
			{
				lines.push("  none for this host");
			}
			else
			{
				for (library in libraries)
				{
					lines.push("  " + library);
				}
			}
		}

		return lines;
	}

	private static function describeHaxelib(path:String):String
	{
		if (path == null || path == "") return "not installed";

		var version = getHaxelibVersion(path);
		var description = (version != null ? version : "unknown version");
		var root = Path.standardize(path, false);

		if (NativeSourcesHelper.isGitCheckout(root))
		{
			var commit = run("git", ["-C", root, "rev-parse", "HEAD"]);

			if (commit != null)
			{
				description += ", git " + StringTools.trim(commit);

				var status = run("git", ["-C", root, "status", "--porcelain", "--untracked-files=no", "--ignore-submodules=all"]);

				if (status != null && StringTools.trim(status) != "")
				{
					description += " with local changes";
				}
			}
			else
			{
				description += ", git checkout";
			}
		}

		return description + ", " + root;
	}

	private static function describeSubmodules(root:String):String
	{
		var output = run("git", ["-C", root, "submodule", "status", "--recursive"]);
		if (output == null) return "unknown, git submodule status failed";

		var problems = [];

		for (submodule in NativeSourcesHelper.parseSubmoduleStatus(output))
		{
			switch (submodule.state)
			{
				case "-":
					problems.push(submodule.path + " not checked out");
				case "+":
					problems.push(submodule.path + " at " + submodule.commit);
				case "U":
					problems.push(submodule.path + " with merge conflicts");
				default:
			}
		}

		if (problems.length == 0) return "at the commits this checkout pins";
		return "not at the commits this checkout pins: " + problems.join(", ");
	}

	private static function describeLibraries(root:String):Array<String>
	{
		var result = [];
		var directory = Path.combine(root, "ndll");

		var hostPrefix = switch (System.hostPlatform)
		{
			case WINDOWS: "Windows";
			case MAC: "Mac";
			default: "Linux";
		}

		try
		{
			if (!FileSystem.exists(directory)) return result;

			var folders = FileSystem.readDirectory(directory);
			folders.sort(Reflect.compare);

			for (folder in folders)
			{
				var path = Path.combine(directory, folder);
				if (!FileSystem.isDirectory(path)) continue;

				var files = FileSystem.readDirectory(path);
				files.sort(Reflect.compare);

				var recorded = Lambda.exists(files, function(file) return StringTools.endsWith(file, NativeSourcesHelper.RECORD_EXTENSION));
				if (!StringTools.startsWith(folder, hostPrefix) && !recorded) continue;

				for (file in files)
				{
					if (StringTools.startsWith(file, ".")) continue;

					switch (Path.extension(file).toLowerCase())
					{
						case "hash", "sources", "pdb", "exp", "ilk":
							continue;
						default:
					}

					var filePath = Path.combine(path, file);
					if (FileSystem.isDirectory(filePath)) continue;

					result.push(folder + "/" + file + ": " + describeLibrary(filePath));
				}
			}
		}
		catch (e:Dynamic) {}

		return result;
	}

	private static function describeLibrary(path:String):String
	{
		var description = "modified " + DateTools.format(FileSystem.stat(path).mtime, "%Y-%m-%d %H:%M");
		var record = NativeSourcesHelper.readRecord(path);

		if (record == null)
		{
			return description + ", no record of its sources";
		}

		description += ", built from git " + record.commit + " (" + record.source + " tree " + record.tree;

		for (submodule in record.submodules)
		{
			description += ", " + submodule.path + " at " + submodule.commit;
		}

		description += ")";

		var changes = NativeSourcesHelper.getChanges(path);

		if (changes != null)
		{
			description += (changes.length == 0 ? ", matches this checkout" : ", older than this checkout: " + changes.join(", ") + " changed since");
		}

		return description;
	}

	private static function getHostDescription():String
	{
		var description = switch (System.hostPlatform)
		{
			case WINDOWS:
				// Neko quotes arguments in a way cmd does not read, and only this form of the command line runs
				var output = run("cmd.exe /c ver", null);
				var pattern = ~/Version ([0-9.]+)/;
				(output != null && pattern.match(output)) ? "Windows " + pattern.matched(1) : "Windows";

			case MAC:
				var output = run("sw_vers", ["-productVersion"]);
				"macOS" + (output != null ? " " + StringTools.trim(output) : "");

			default:
				var name = null;

				try
				{
					for (line in File.getContent("/etc/os-release").split("\n"))
					{
						if (StringTools.startsWith(line, "PRETTY_NAME="))
						{
							name = StringTools.replace(line.substr(12), "\"", "");
						}
					}
				}
				catch (e:Dynamic) {}

				var kernel = run("uname", ["-sr"]);
				(name != null ? name : Sys.systemName()) + (kernel != null ? " (" + StringTools.trim(kernel) + ")" : "");
		}

		return description + ", " + Std.string(System.hostArchitecture).toLowerCase();
	}

	private static function getHaxeVersion():String
	{
		try
		{
			var process = new Process("haxe", ["-version"]);
			var output = StringTools.trim(process.stdout.readAll().toString());
			var error = StringTools.trim(process.stderr.readAll().toString());
			process.close();

			if (output == "") output = error;
			return (output != "" ? output : "unknown");
		}
		catch (e:Dynamic)
		{
			return "not found";
		}
	}

	/**
		The C++ compiler hxcpp picks on this host. On Windows, hxcpp itself is asked, as it
		chooses between MSVC and MinGW from its config and the environment.
	**/
	private static function getCompilerDescription(hxcppPath:String):String
	{
		switch (System.hostPlatform)
		{
			case WINDOWS:
				if (hxcppPath == null || hxcppPath == "") return "unknown, hxcpp is not installed";

				var output = runHxcppProbe();
				if (output == null) return "unknown, hxcpp did not run";

				var compiler = null;
				var installation = null;
				var mingw = false;

				for (line in ~/\r?\n/g.split(output))
				{
					line = StringTools.trim(line);
					var msvc = ~/^MSVC output:.*Version ([0-9.]+) for (\S+)/;

					if (msvc.match(line))
					{
						compiler = "MSVC " + msvc.matched(1) + " (" + msvc.matched(2) + ")";
					}
					else if (StringTools.startsWith(line, "msvs VCINSTALLDIR="))
					{
						installation = line.substr("msvs VCINSTALLDIR=".length);
					}
					else if (line.indexOf("Using Windows compiler: MinGW") > -1)
					{
						mingw = true;
					}
				}

				if (mingw)
				{
					var version = run("g++", ["--version"]);
					return "MinGW" + (version != null ? ", " + firstLine(version) : ", g++ not found");
				}

				if (compiler != null)
				{
					return compiler + (installation != null ? ", " + installation : "");
				}

				var error = null;

				for (line in ~/\r?\n/g.split(output))
				{
					if (line.indexOf("Error") > -1) error = StringTools.trim(line);
				}

				return "unknown" + (error != null ? ", hxcpp said: " + error : "");

			case MAC:
				var version = run("clang", ["--version"]);
				return version != null ? firstLine(version) : "clang not found";

			default:
				var compiler = (Sys.getEnv("HXCPP_CLANG") != null ? "clang++" : "g++");
				var version = run(compiler, ["--version"]);
				return version != null ? firstLine(version) : compiler + " not found";
		}
	}

	// hxcpp names the compiler it sets up when it reads a build file with -verbose
	private static function runHxcppProbe():String
	{
		var directory = null;

		try
		{
			directory = System.getTemporaryDirectory();
			var buildFile = Path.combine(directory, "Build.xml");
			File.saveContent(buildFile, '<xml>\n\t<include name="$${HXCPP}/build-tool/BuildCommon.xml" />\n\t<target id="default" />\n</xml>\n');

			var args = ["run", "hxcpp", buildFile, "-verbose"];

			if (System.hostArchitecture == X64)
			{
				args.push("-DHXCPP_M64");
			}

			Sys.putEnv("HXCPP_NO_COLOR", "1");
			var output = run("haxelib", args, true);

			System.removeDirectory(directory);
			return output != null ? ~/\x1b\[[0-9;]*m/g.replace(output, "") : null;
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	private static function firstLine(text:String):String
	{
		return StringTools.trim(~/\r?\n/g.split(StringTools.trim(text))[0]);
	}

	private static function readHaxelibJson(path:String):Dynamic
	{
		if (path == null || path == "") return null;

		try
		{
			return Json.parse(File.getContent(Path.combine(path, "haxelib.json")));
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	// Runs a program and returns what it printed, or null when it could not run or failed.
	// Without arguments, the command is run by the shell.
	private static function run(command:String, args:Array<String>, includeErrors:Bool = false):String
	{
		try
		{
			var process = new Process(command, args);
			var output = process.stdout.readAll().toString();
			var errors = process.stderr.readAll().toString();
			var exitCode = process.exitCode();
			process.close();

			if (includeErrors) return output + errors;
			return (exitCode == 0 ? output : null);
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}
}
