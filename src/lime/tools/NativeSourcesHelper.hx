package lime.tools;

import hxp.*;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

/**
	What the native libraries of a library that is a git checkout, such as lime.ndll in a
	clone of Lime, were built from.

	`lime rebuild` writes a record beside each library file it builds (`lime.ndll.sources`
	beside `lime.ndll`): the commit, the git tree of the folder it built (`project`) and the
	commit of each submodule there that is not at the commit the tree pins. A build that uses
	the file compares the record with the checkout, and warns when the native sources have
	changed since, as they do after a pull that is not followed by `lime rebuild`.

	A library without a `.git` folder, such as a haxelib release, is not checked, and neither
	is a file without a record.
**/
class NativeSourcesHelper
{
	/**
		The extension of the record beside each library file.
	**/
	public static inline var RECORD_EXTENSION = ".sources";

	private static var checkedLibraries = new Map<String, Bool>();
	private static var checkedSubmodules = new Map<String, Bool>();

	/**
		Warns, once for each file, when a library file a build uses was built from older native
		sources than its checkout has.
	**/
	public static function checkLibrary(path:String):Void
	{
		if (path == null || path == "") return;

		var key = comparablePath(path);
		if (checkedLibraries.exists(key)) return;
		checkedLibraries.set(key, true);

		var message = getStaleMessage(path);

		if (message != null)
		{
			Log.warn(message);
		}
	}

	/**
		Warns, once for each checkout, when the submodules of the library a rebuild compiles
		are not at the commits its checkout pins.
	**/
	public static function checkSubmodules(path:String):Void
	{
		var root = getLibraryRoot(path);
		if (root == null || !isGitCheckout(root)) return;

		var key = comparablePath(root);
		if (checkedSubmodules.exists(key)) return;
		checkedSubmodules.set(key, true);

		var message = getSubmoduleMessage(root);

		if (message != null)
		{
			Log.warn(message);
		}
	}

	/**
		Runs `build`, the rebuild of the native project in `path` (the folder with Build.xml),
		and records the sources beside each file it writes to the library's `ndll` folder.

		The record of a file that hxcpp leaves alone because it is up to date would stay as it
		was, so before the build, hxcpp's hash of each file whose record is missing or older is
		removed. hxcpp then links each library this build makes again, and each gets a record.
	**/
	public static function rebuild(path:String, build:Void->Void):Void
	{
		var root = getLibraryRoot(path);

		if (root == null || System.dryRun || !isGitCheckout(root))
		{
			build();
			return;
		}

		checkSubmodules(path);

		var source = getRelativePath(root, path);
		var sources = (source != null ? readSources(root, source) : null);

		if (sources == null)
		{
			build();
			return;
		}

		var outputDirectory = Path.combine(root, "ndll");
		var before = listLibraries(outputDirectory);
		var unhashed = new Map<String, Bool>();

		for (file in before.keys())
		{
			var record = readRecord(file);

			if (record == null || !record.matches(sources))
			{
				var hash = file + ".hash";

				try
				{
					if (FileSystem.exists(hash)) FileSystem.deleteFile(hash);
				}
				catch (e:Dynamic) {}

				// An earlier hxcpp run of this rebuild, for another architecture, may have removed it
				if (!FileSystem.exists(hash)) unhashed.set(file, true);
			}
		}

		build();

		var after = listLibraries(outputDirectory);

		for (file in after.keys())
		{
			// A link in the same second that makes a file of the same size still writes the hash again
			if (before.get(file) != after.get(file) || (unhashed.exists(file) && FileSystem.exists(file + ".hash")))
			{
				try
				{
					File.saveContent(file + RECORD_EXTENSION, sources.toString());
				}
				catch (e:Dynamic)
				{
					Log.info("", " - Could not record the sources of " + file);
				}
			}
		}
	}

	/**
		The warning to show for a library file built from older native sources than its
		checkout has, or `null` when it was built from these sources, or that is not known.
	**/
	public static function getStaleMessage(path:String):String
	{
		var changes = getChanges(path);
		if (changes == null || changes.length == 0) return null;

		if (changes.length > 3)
		{
			changes = changes.slice(0, 3).concat(["and " + (changes.length - 3) + " more"]);
		}

		return Path.withoutDirectory(path)
			+ " in "
			+ Path.standardize(Path.directory(FileSystem.fullPath(path)), false)
			+ " was built from older native sources than this checkout has ("
			+ changes.join(", ")
			+ " changed since). Builds that use it can fail or crash in ways that are hard to trace. To build it again, run: "
			+ getRebuildCommand(getLibraryRootOfFile(path), path);
	}

	/**
		What has changed in the checkout since a library file was built: the folder that was
		built when its tree changed, and each submodule that moved. Returns `null` when that is
		not known: the file has no record, or its library is not a git checkout.
	**/
	public static function getChanges(path:String):Array<String>
	{
		var record = readRecord(path);
		if (record == null) return null;

		var root = getLibraryRootOfFile(path);
		if (root == null || !isGitCheckout(root)) return null;

		var current = readSources(root, record.source);
		if (current == null) return null;

		return record.getChanges(current);
	}

	/**
		The warning to show when submodules of the checkout in `root` are not at the commits
		it pins, or `null` when they are or git cannot tell.
	**/
	public static function getSubmoduleMessage(root:String):String
	{
		var output = git(root, ["submodule", "status", "--recursive"]);
		if (output == null) return null;

		var problems = [];

		for (submodule in parseSubmoduleStatus(output))
		{
			switch (submodule.state)
			{
				case "-":
					problems.push(submodule.path + " (not checked out)");
				case "+":
					problems.push(submodule.path + " (at another commit)");
				case "U":
					problems.push(submodule.path + " (with merge conflicts)");
				default:
			}
		}

		if (problems.length == 0) return null;

		return "Submodules of "
			+ Path.standardize(root, false)
			+ " are not at the commits this checkout pins: "
			+ problems.join(", ")
			+ ". The native libraries would be built from other sources than this checkout is made for, or fail to build. To update them, run this in "
			+ Path.standardize(root, false)
			+ ": git submodule update --init --recursive";
	}

	/**
		Reads the lines of `git submodule status`: a state (" " at the pinned commit, "+" at
		another commit, "-" not checked out, "U" with merge conflicts), the commit and the path.
	**/
	public static function parseSubmoduleStatus(output:String):Array<SubmoduleStatus>
	{
		var result = [];
		if (output == null) return result;

		var pattern = ~/^([ +\-U])([0-9a-fA-F]+) (\S+)/;

		for (line in ~/\r?\n/g.split(output))
		{
			if (pattern.match(line))
			{
				result.push({state: pattern.matched(1), commit: pattern.matched(2), path: pattern.matched(3)});
			}
		}

		return result;
	}

	/**
		Reads the record beside a library file, or returns `null` when there is none.
	**/
	public static function readRecord(path:String):NativeSources
	{
		var recordPath = path + RECORD_EXTENSION;

		try
		{
			if (!FileSystem.exists(recordPath)) return null;
			return NativeSources.parse(File.getContent(recordPath));
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	/**
		What the folder `source` (relative to `root`) of a git checkout holds now: the commit,
		its tree, and its submodules that are not at the commits the tree pins. Returns `null`
		when git cannot tell, for example when git is not installed.
	**/
	public static function readSources(root:String, source:String):NativeSources
	{
		var directory = Path.combine(root, source);
		if (!FileSystem.exists(directory)) return null;

		var revisions = git(directory, ["rev-parse", "HEAD", "HEAD:./"]);
		if (revisions == null) return null;

		var lines = ~/\r?\n/g.split(StringTools.trim(revisions));
		if (lines.length < 2) return null;

		var sources = new NativeSources();
		sources.commit = StringTools.trim(lines[0]);
		sources.source = Path.standardize(source, false);
		sources.tree = StringTools.trim(lines[1]);

		// The tree holds the commit each submodule is pinned to. diff-index names the ones
		// checked out at another commit in a fraction of the time git submodule status takes.
		var differences = git(directory, ["diff-index", "--ignore-submodules=dirty", "HEAD", "--", "."]);
		if (differences == null) return null;

		var pattern = ~/^:(\d+) (\d+) [0-9a-fA-F]+ [0-9a-fA-F]+ \S+\t(.+)$/;
		var moved = [];

		for (line in ~/\r?\n/g.split(differences))
		{
			if (pattern.match(line) && (pattern.matched(1) == "160000" || pattern.matched(2) == "160000"))
			{
				moved.push(pattern.matched(3));
			}
		}

		if (moved.length > 0)
		{
			// diff-index names paths from the top of the repository
			var top = git(directory, ["rev-parse", "--show-toplevel"]);
			top = (top != null ? StringTools.trim(top) : root);

			for (path in moved)
			{
				var submodulePath = Path.combine(top, path);
				var commit = FileSystem.exists(submodulePath) ? git(submodulePath, ["rev-parse", "HEAD"]) : null;
				sources.submodules.push({path: path, commit: commit != null ? StringTools.trim(commit) : "none"});
			}

			sources.submodules.sort(function(a, b) return a.path < b.path ? -1 : (a.path > b.path ? 1 : 0));
		}

		return sources;
	}

	/**
		The folder of a library, from the folder of its native project, or `null`.
	**/
	public static function getLibraryRoot(path:String):String
	{
		if (path == null || path == "") return null;

		try
		{
			var fullPath = Path.standardize(FileSystem.fullPath(path), false);

			if (!FileSystem.isDirectory(fullPath))
			{
				fullPath = Path.directory(fullPath);
			}

			var root = Path.directory(fullPath);
			return (root == "" ? null : root);
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	// A library file is in <library>/ndll/<folder>/
	private static function getLibraryRootOfFile(path:String):String
	{
		try
		{
			var root = Path.directory(Path.directory(Path.directory(Path.standardize(FileSystem.fullPath(path), false))));
			return (root == "" ? null : root);
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	/**
		Whether a library folder is a git checkout. A haxelib release has no `.git`.
	**/
	public static function isGitCheckout(root:String):Bool
	{
		return root != null && FileSystem.exists(Path.combine(root, ".git"));
	}

	private static function comparablePath(path:String):String
	{
		try
		{
			path = FileSystem.fullPath(path);
		}
		catch (e:Dynamic) {}

		path = Path.standardize(path, false);
		return System.hostPlatform == WINDOWS ? path.toLowerCase() : path;
	}

	private static function getRebuildCommand(root:String, path:String):String
	{
		var directory = Path.withoutDirectory(Path.directory(FileSystem.fullPath(path)));
		var target = getTargetName(directory, Path.extension(path));
		var command = "lime rebuild ";

		var name = null;

		try
		{
			name = haxe.Json.parse(File.getContent(Path.combine(root, "haxelib.json"))).name;
		}
		catch (e:Dynamic) {}

		if (name != null && name != "lime")
		{
			command += name + " ";
		}

		command += target;

		if (Path.withoutDirectory(path).indexOf("-debug") > -1)
		{
			command += " -debug";
		}

		return command;
	}

	/**
		The `lime rebuild` target that builds the files of an ndll folder such as `Windows64`.
	**/
	public static function getTargetName(directory:String, extension:String):String
	{
		if (extension == "hdll") return "hl";

		var targets = [
			["WinRT", "winrt"],
			["Windows", "windows"],
			["Linux", "linux"],
			["RPi", "rpi"],
			["Mac", "mac"],
			["Android", "android"],
			["iPhone", "ios"],
			["AppleTV", "tvos"],
			["Emscripten", "webassembly"],
			["Tizen", "tizen"]
		];

		for (target in targets)
		{
			if (StringTools.startsWith(directory, target[0]))
			{
				return target[1];
			}
		}

		return directory.toLowerCase();
	}

	private static function getRelativePath(root:String, path:String):String
	{
		try
		{
			var fullRoot = Path.standardize(FileSystem.fullPath(root), false);
			var fullPath = Path.standardize(FileSystem.fullPath(path), false);

			if (!FileSystem.isDirectory(fullPath))
			{
				fullPath = Path.directory(fullPath);
			}

			if (comparablePath(fullPath) == comparablePath(fullRoot)) return ".";

			if (StringTools.startsWith(comparablePath(fullPath), comparablePath(fullRoot) + "/"))
			{
				return fullPath.substr(fullRoot.length + 1);
			}
		}
		catch (e:Dynamic) {}

		return null;
	}

	// Each library file in the folders of an ndll folder, with its time and size
	private static function listLibraries(directory:String):Map<String, String>
	{
		var result = new Map<String, String>();

		try
		{
			if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory)) return result;

			for (name in FileSystem.readDirectory(directory))
			{
				var subdirectory = Path.combine(directory, name);
				if (!FileSystem.isDirectory(subdirectory)) continue;

				for (file in FileSystem.readDirectory(subdirectory))
				{
					if (StringTools.startsWith(file, ".")) continue;

					switch (Path.extension(file).toLowerCase())
					{
						case "hash", "sources", "pdb", "exp", "ilk":
							continue;
						default:
					}

					var path = Path.combine(subdirectory, file);
					if (FileSystem.isDirectory(path)) continue;

					var stat = FileSystem.stat(path);
					result.set(path, stat.mtime.getTime() + ":" + stat.size);
				}
			}
		}
		catch (e:Dynamic) {}

		return result;
	}

	private static function git(directory:String, args:Array<String>):String
	{
		try
		{
			var process = new Process("git", ["-C", directory].concat(args));
			var output = process.stdout.readAll().toString();
			process.stderr.readAll();
			var exitCode = process.exitCode();
			process.close();

			return (exitCode == 0 ? output : null);
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}
}

/**
	What a native library was built from, as `NativeSourcesHelper` records it.
**/
class NativeSources
{
	/**
		The commit checked out, for people reading the record. Builds compare the tree.
	**/
	public var commit:String;

	/**
		The folder that was built, relative to the library, such as `project`.
	**/
	public var source:String;

	/**
		The submodules in `source` that were not at the commits `tree` pins, with the commit
		each was at (`none` when not checked out).
	**/
	public var submodules:Array<{path:String, commit:String}>;

	/**
		The git tree of `source`, which also holds the commit each submodule is pinned to.
	**/
	public var tree:String;

	public function new()
	{
		submodules = [];
	}

	/**
		The parts of `current` that differ from this record: `source` when its tree changed,
		and the path of each submodule that moved.
	**/
	public function getChanges(current:NativeSources):Array<String>
	{
		var changes = [];

		if (tree != current.tree)
		{
			changes.push(source);
		}

		var recorded = new Map<String, String>();
		for (submodule in submodules) recorded.set(submodule.path, submodule.commit);

		var now = new Map<String, String>();
		for (submodule in current.submodules) now.set(submodule.path, submodule.commit);

		for (path in recorded.keys())
		{
			if (now.get(path) != recorded.get(path) && changes.indexOf(path) == -1) changes.push(path);
		}

		for (path in now.keys())
		{
			if (recorded.get(path) != now.get(path) && changes.indexOf(path) == -1) changes.push(path);
		}

		return changes;
	}

	public function matches(current:NativeSources):Bool
	{
		return source == current.source && getChanges(current).length == 0;
	}

	public static function parse(text:String):NativeSources
	{
		var sources = new NativeSources();

		for (line in ~/\r?\n/g.split(text))
		{
			line = StringTools.trim(line);
			if (line == "" || StringTools.startsWith(line, "#")) continue;

			var space = line.indexOf(" ");
			if (space == -1) continue;

			var key = line.substr(0, space);
			var value = StringTools.trim(line.substr(space + 1));

			switch (key)
			{
				case "commit":
					sources.commit = value;
				case "source":
					sources.source = value;
				case "tree":
					sources.tree = value;
				case "submodule":
					var separator = value.lastIndexOf(" ");
					if (separator > -1)
					{
						sources.submodules.push({path: value.substr(0, separator), commit: value.substr(separator + 1)});
					}
				default:
			}
		}

		return (sources.source != null && sources.tree != null ? sources : null);
	}

	public function toString():String
	{
		var lines = [
			"# Written by lime rebuild: the git sources this file was built from",
			"commit " + commit,
			"source " + source,
			"tree " + tree
		];

		for (submodule in submodules)
		{
			lines.push("submodule " + submodule.path + " " + submodule.commit);
		}

		return lines.join("\n") + "\n";
	}
}

typedef SubmoduleStatus =
{
	var state:String;
	var commit:String;
	var path:String;
}
