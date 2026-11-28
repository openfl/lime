package system;

import lime.system.System;
import utest.Assert;
import utest.Test;
#if sys
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end

/**
	`System.getFreeSpace()`, `System.isSymbolicLink()` and `System.isHidden()`,
	against what the system's own tools report and set, in a folder of the
	temporary folder.
**/
class FileSystemInfoTest extends Test
{
	// Other programs write while the tests run
	private static inline var SPACE_TOLERANCE = 256.0 * 1024 * 1024;

	#if sys
	private var folder:String;
	#end

	public function new()
	{
		super();
	}

	public function testNoPathHasNoSpaceAndIsNoLink():Void
	{
		Assert.equals(-1.0, System.getFreeSpace(""));
		Assert.equals(-1.0, System.getFreeSpace(null));
		Assert.isFalse(System.isSymbolicLink(""));
		Assert.isFalse(System.isSymbolicLink(null));
		Assert.isFalse(System.isHidden(""));
		Assert.isFalse(System.isHidden(null));
	}

	#if (lime_cffi && !macro && (windows || mac || linux))
	public function setup():Void
	{
		folder = Path.join([temporaryFolder(), "lime-test-files-" + Std.random(0x3FFFFFFF)]);
		FileSystem.createDirectory(folder);
	}

	public function teardown():Void
	{
		remove(folder);
	}

	public function testTheTemporaryFolderHasTheFreeSpaceTheSystemReports():Void
	{
		var free = System.getFreeSpace(folder);
		var reported = reportedFreeSpace(folder);

		Assert.isTrue(free > 0, "free space " + free);
		Assert.isTrue(reported > 0, "the system reported " + reported);
		Assert.isTrue(Math.abs(free - reported) < SPACE_TOLERANCE, "free space " + free + ", where the system reports " + reported);
	}

	public function testAFileHasTheSpaceOfItsVolume():Void
	{
		var file = Path.join([folder, "file.txt"]);
		File.saveContent(file, "text");

		var free = System.getFreeSpace(folder);
		Assert.isTrue(Math.abs(System.getFreeSpace(file) - free) < SPACE_TOLERANCE, "a file has " + System.getFreeSpace(file) + ", its folder " + free);
	}

	public function testAMissingPathHasTheSpaceOfItsFolderOnlyOnWindows():Void
	{
		var missing = Path.join([folder, "missing", "file.txt"]);

		#if windows
		var free = System.getFreeSpace(folder);
		Assert.isTrue(Math.abs(System.getFreeSpace(missing) - free) < SPACE_TOLERANCE, "a missing path has " + System.getFreeSpace(missing) + ", its folder " + free);
		#else
		Assert.equals(-1.0, System.getFreeSpace(missing));
		#end
	}

	public function testAVolumeThatIsNotThereHasNoSpace():Void
	{
		#if windows
		var drive = unusedDrive();
		if (drive == null)
		{
			// utest takes a warning as a failure, so the test passes, saying why
			trace("Every drive letter is in use, so a missing drive was not tested");
			Assert.pass();
			return;
		}

		Assert.equals(-1.0, System.getFreeSpace(drive + ":\\"));
		Assert.equals(-1.0, System.getFreeSpace(drive + ":\\folder\\file.txt"));
		#else
		Assert.equals(-1.0, System.getFreeSpace("/lime-test-missing-" + Std.random(0x3FFFFFFF) + "/file.txt"));
		#end
	}

	public function testALinkIsFoundWithoutFollowingIt():Void
	{
		var target = Path.join([folder, "target"]);
		var file = Path.join([folder, "file.txt"]);
		var link = Path.join([folder, "link"]);
		FileSystem.createDirectory(target);
		File.saveContent(file, "text");

		Assert.isTrue(makeLink(link, target), "the link could not be made");
		Assert.isTrue(FileSystem.exists(link), "the link does not exist");

		Assert.isTrue(System.isSymbolicLink(link), "a link to a folder is not a link");
		Assert.isFalse(System.isSymbolicLink(target), "a folder is a link");
		Assert.isFalse(System.isSymbolicLink(file), "a file is a link");
		Assert.isFalse(System.isSymbolicLink(folder), "the folder holding a link is a link");
		Assert.isFalse(System.isSymbolicLink(Path.join([folder, "missing"])), "a missing path is a link");

		// The link's own space is its volume's
		Assert.isTrue(System.getFreeSpace(link) > 0);

		#if !windows
		// Files can be linked to without rights on Linux and macOS
		var fileLink = Path.join([folder, "file-link"]);
		Assert.isTrue(makeLink(fileLink, file));
		Assert.isTrue(System.isSymbolicLink(fileLink), "a link to a file is not a link");
		#end

		// A link whose target is gone is still a link
		FileSystem.deleteDirectory(target);
		Assert.isTrue(System.isSymbolicLink(link), "a link whose target is gone is not a link");
	}

	public function testHiddenFilesAndFoldersAreFound():Void
	{
		var file = Path.join([folder, "file.txt"]);
		var subfolder = Path.join([folder, "folder"]);
		var dotFile = Path.join([folder, ".file"]);
		var dotFolder = Path.join([folder, ".folder"]);
		File.saveContent(file, "text");
		FileSystem.createDirectory(subfolder);
		File.saveContent(dotFile, "text");
		FileSystem.createDirectory(dotFolder);

		Assert.isFalse(System.isHidden(file), "a file is hidden");
		Assert.isFalse(System.isHidden(subfolder), "a folder is hidden");
		Assert.isFalse(System.isHidden(folder + "/."), "a folder named by . is hidden");
		Assert.isFalse(System.isHidden(Path.join([folder, ".missing"])), "a missing path is hidden");

		#if windows
		// Explorer shows a name that starts with a dot, and hides what has the hidden attribute
		Assert.isFalse(System.isHidden(dotFile), "a file named with a dot is hidden");
		Assert.isFalse(System.isHidden(dotFolder), "a folder named with a dot is hidden");

		Assert.isTrue(setHidden(file, true), "the hidden attribute could not be set on a file");
		Assert.isTrue(System.isHidden(file), "a file with the hidden attribute is not hidden");
		Assert.isTrue(setHidden(subfolder, true), "the hidden attribute could not be set on a folder");
		Assert.isTrue(System.isHidden(subfolder), "a folder with the hidden attribute is not hidden");

		Assert.isTrue(setHidden(file, false), "the hidden attribute could not be taken off");
		Assert.isFalse(System.isHidden(file), "a file whose hidden attribute was taken off is hidden");
		#else
		// ls and file managers leave out a name that starts with a dot
		Assert.isTrue(System.isHidden(dotFile), "a file named with a dot is not hidden");
		Assert.isTrue(System.isHidden(dotFolder), "a folder named with a dot is not hidden");
		Assert.isTrue(System.isHidden(dotFolder + "/"), "a folder named with a dot, given with a slash after it, is not hidden");

		#if mac
		// The Finder also hides what has the hidden flag
		Assert.equals(0, Sys.command("chflags", ["hidden", file]), "the hidden flag could not be set");
		Assert.isTrue(System.isHidden(file), "a file with the hidden flag is not hidden");
		Assert.equals(0, Sys.command("chflags", ["nohidden", file]), "the hidden flag could not be taken off");
		Assert.isFalse(System.isHidden(file), "a file whose hidden flag was taken off is hidden");
		#end
		#end
	}

	#if !neko
	public function testPathsOutsideASCII():Void
	{
		// Neko's file functions do not take paths outside ASCII on Windows
		var named = Path.join([folder, "café 漢"]);
		FileSystem.createDirectory(named);
		var target = Path.join([named, "target é"]);
		FileSystem.createDirectory(target);
		var link = Path.join([named, "link 漢"]);

		Assert.isTrue(System.getFreeSpace(named) > 0, "a folder named outside ASCII has " + System.getFreeSpace(named));
		Assert.isFalse(System.isSymbolicLink(named));
		Assert.isTrue(makeLink(link, target), "the link could not be made");
		Assert.isTrue(System.isSymbolicLink(link), "a link named outside ASCII is not a link");

		var hidden = Path.join([named, #if windows "hidden é" #else ".hidden é" #end]);
		File.saveContent(hidden, "text");
		#if windows
		Assert.isTrue(setHidden(hidden, true), "the hidden attribute could not be set");
		#end
		Assert.isFalse(System.isHidden(named), "a folder named outside ASCII is hidden");
		Assert.isTrue(System.isHidden(hidden), "a hidden file named outside ASCII is not hidden");
	}
	#end

	#if windows
	private static function setHidden(path:String, hidden:Bool):Bool
	{
		// The hidden attribute, set by PowerShell, which takes any name
		var item = "$item = Get-Item -LiteralPath '" + path.split("'").join("''") + "' -Force";
		var attributes = hidden ? "$item.Attributes = $item.Attributes -bor [IO.FileAttributes]::Hidden" : "$item.Attributes = $item.Attributes -band -bnot [IO.FileAttributes]::Hidden";
		return powerShell(item + "\n" + attributes) != null;
	}
	#end

	private static function makeLink(link:String, target:String):Bool
	{
		#if windows
		// A junction, which needs no rights, made by PowerShell, which takes any name
		return powerShell("New-Item -ItemType Junction -Path '" + link.split("'").join("''") + "' -Target '" + target.split("'").join("''")
			+ "' | Out-Null") != null;
		#else
		return Sys.command("ln", ["-s", target, link]) == 0;
		#end
	}

	private static function remove(path:String):Void
	{
		if (path == null) return;

		if (System.isSymbolicLink(path))
		{
			// The link and not what it leads to
			#if windows
			FileSystem.deleteDirectory(path);
			#else
			FileSystem.deleteFile(path);
			#end
			return;
		}

		if (!FileSystem.exists(path)) return;

		if (FileSystem.isDirectory(path))
		{
			for (entry in FileSystem.readDirectory(path))
			{
				remove(Path.join([path, entry]));
			}

			FileSystem.deleteDirectory(path);
		}
		else
		{
			FileSystem.deleteFile(path);
		}
	}

	private static function reportedFreeSpace(path:String):Float
	{
		#if windows
		// The space this user may use, as GetDiskFreeSpaceEx reports it
		var output = powerShell("[System.IO.DriveInfo]::new('" + path.substr(0, 1) + "').AvailableFreeSpace");
		return output != null ? Std.parseFloat(output) : -1;
		#else
		// The space this user may use, in kilobyte blocks, in the fourth column
		var process = new sys.io.Process("df", ["-Pk", path]);
		var lines = StringTools.trim(process.stdout.readAll().toString()).split("\n");
		process.close();
		var columns = ~/\s+/g.split(StringTools.trim(lines[lines.length - 1]));
		return columns.length > 3 ? Std.parseFloat(columns[3]) * 1024 : -1;
		#end
	}

	private static function temporaryFolder():String
	{
		for (name in ["TEMP", "TMPDIR", "TMP"])
		{
			var value = Sys.getEnv(name);
			if (value != null && value != "") return value;
		}

		return "/tmp";
	}

	#if windows
	/**
		Runs a PowerShell command, and returns what it writes, or `null` when it
		fails.
	**/
	private static function powerShell(command:String):String
	{
		var script = "$ErrorActionPreference = 'Stop'\n" + command + "\n";

		// An encoded command is UTF-16, and needs no quoting
		var utf16 = haxe.io.Bytes.alloc(script.length * 2);
		for (i in 0...script.length)
		{
			utf16.setUInt16(i * 2, StringTools.fastCodeAt(script, i));
		}

		// HashLink starts a process by its path, without looking through PATH
		var root = Sys.getEnv("SystemRoot");
		var path = root != null ? root + "\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" : null;
		var executable = path != null && FileSystem.exists(path) ? path : "powershell";

		var process = new sys.io.Process(executable, ["-NoProfile", "-NonInteractive", "-EncodedCommand", haxe.crypto.Base64.encode(utf16)]);
		var output = process.stdout.readAll().toString();
		var exitCode = process.exitCode();
		process.close();
		return exitCode == 0 ? StringTools.trim(output) : null;
	}

	private static function unusedDrive():String
	{
		for (code in "D".code..."Z".code + 1)
		{
			var drive = String.fromCharCode("Z".code + "D".code - code);
			if (!FileSystem.exists(drive + ":\\")) return drive;
		}

		return null;
	}
	#end
	#else
	public function testNothingIsKnownWithoutTheNativeLibrary():Void
	{
		// Web and Flash have no files of their own to ask about
		Assert.equals(-1.0, System.getFreeSpace("/"));
		Assert.isFalse(System.isSymbolicLink("/"));
	}
	#end
}
