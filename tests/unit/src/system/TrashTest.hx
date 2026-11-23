package system;

import lime.system.System;
import utest.Assert;
import utest.Async;
import utest.Test;
#if sys
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end

/**
	`System.moveToTrash` and `moveToTrashAsync`.

	Moving files to the trash puts them in the user's own, so those tests only
	run where `LIME_TEST_TRASH` is `1`, as on CI. They find each file in the
	trash, and on Windows restore it from the Recycle Bin, as a user would,
	before deleting it, so nothing is left there.
**/
class TrashTest extends Test
{
	public function new()
	{
		super();
	}

	public function testNothingIsMovedWithoutAPath():Void
	{
		Assert.isFalse(System.moveToTrash(""));
		Assert.isFalse(System.moveToTrash(null));
	}

	#if (lime_cffi && !macro && (windows || mac || linux))
	public function testAMissingPathIsNotMoved():Void
	{
		var missing = Path.join([temporaryFolder(), "lime-test-trash-missing-" + Std.random(0x3FFFFFFF)]);
		Assert.isFalse(System.moveToTrash(missing));

		// Boxed, as for a Future's result: HashLink 1.16's JIT boxed a native function's false as true on macOS
		var boxed:Dynamic = System.moveToTrash(missing);
		Assert.isFalse(boxed, "moveToTrash gave " + boxed + " once boxed");
	}

	@:timeout(10000)
	public function testAMissingPathIsNotMovedOnABackgroundThread(async:Async):Void
	{
		var missing = Path.join([temporaryFolder(), "lime-test-trash-missing-" + Std.random(0x3FFFFFFF)]);

		System.moveToTrashAsync(missing).onComplete(function(moved)
		{
			// Says what came back, as only macOS HashLink gave something other than false here
			Assert.isFalse(moved, "moveToTrashAsync completed with " + moved + " (" + Type.typeof(moved) + ")");
			Assert.isTrue(lime.system.ThreadPool.isMainThread(), "the result came on another thread");
			async.done();
		}).onError(function(error)
		{
			Assert.fail("" + error);
			async.done();
		});
	}

	public function testAFileGoesToTheTrashAndCanBeRestored():Void
	{
		if (!canRun()) return;

		var file = newFile("lime-test-trash-" + Std.random(0x3FFFFFFF) + ".txt");
		Assert.isTrue(System.moveToTrash(file), "the file was not moved to the trash");
		Assert.isFalse(FileSystem.exists(file), "the file is still where it was");
		assertInTrashAndRestore(file);
	}

	#if !neko
	public function testAFileNamedOutsideASCIIGoesToTheTrash():Void
	{
		// Neko's file functions do not take paths outside ASCII on Windows
		if (!canRun()) return;

		var file = newFile("lime-test-trash-café 漢-" + Std.random(0x3FFFFFFF) + ".txt");
		Assert.isTrue(System.moveToTrash(file), "a file named outside ASCII was not moved to the trash");
		Assert.isFalse(FileSystem.exists(file), "the file is still where it was");
		assertInTrashAndRestore(file);
	}
	#end

	public function testAFolderGoesToTheTrashWithWhatItHolds():Void
	{
		if (!canRun()) return;

		var folder = Path.join([temporaryFolder(), "lime-test-trash-folder-" + Std.random(0x3FFFFFFF)]);
		FileSystem.createDirectory(folder);
		File.saveContent(Path.join([folder, "inside.txt"]), "inside");

		Assert.isTrue(System.moveToTrash(folder), "the folder was not moved to the trash");
		Assert.isFalse(FileSystem.exists(folder), "the folder is still where it was");
		assertInTrashAndRestore(folder);
	}

	@:timeout(20000)
	public function testAFileGoesToTheTrashOnABackgroundThread(async:Async):Void
	{
		if (!canRun())
		{
			async.done();
			return;
		}

		var file = newFile("lime-test-trash-async-" + Std.random(0x3FFFFFFF) + ".txt");

		System.moveToTrashAsync(file).onComplete(function(moved)
		{
			Assert.isTrue(moved, "the file was not moved to the trash");
			Assert.isFalse(FileSystem.exists(file), "the file is still where it was");
			if (moved) assertInTrashAndRestore(file);
			async.done();
		}).onError(function(error)
		{
			Assert.fail("" + error);
			async.done();
		});
	}

	private static function canRun():Bool
	{
		if (Sys.getEnv("LIME_TEST_TRASH") == "1")
		{
			#if (native_desktop < "1.2.0")
			// Moving to the trash needs native-desktop 1.2.0
			var probe = newFile("lime-test-trash-probe-" + Std.random(0x3FFFFFFF) + ".txt");

			if (!System.moveToTrash(probe))
			{
				if (FileSystem.exists(probe)) FileSystem.deleteFile(probe);
				trace("native-desktop " + haxe.macro.Compiler.getDefine("native-desktop") + " cannot move files to the trash, so it was not tested");
				Assert.pass();
				return false;
			}

			assertInTrashAndRestore(probe);
			#end

			return true;
		}

		// utest takes a warning as a failure, so the test passes, saying why
		trace("LIME_TEST_TRASH is not 1, so nothing was moved to the trash");
		Assert.pass();
		return false;
	}

	/**
		Finds what was at `path` in the trash, and takes it out: on Windows by
		restoring it from the Recycle Bin, as the user would, and elsewhere
		from the trash folder. Then deletes it.
	**/
	private static function assertInTrashAndRestore(path:String):Void
	{
		var name = Path.withoutDirectory(path);

		#if windows
		var restored = powerShell("$name = '" + name.split("'").join("''") + "'\n"
			+ "$bin = (New-Object -ComObject Shell.Application).Namespace(10)\n"
			+ "$item = $bin.Items() | Where-Object { $_.ExtendedProperty('System.FileName') -eq $name } | Select-Object -First 1\n"
			+ "if ($item -eq $null) { exit 2 }\n"
			+ "$item.InvokeVerb('undelete')\n");
		Assert.isTrue(restored == 0, restored == 2 ? name + " is not in the Recycle Bin" : name + " could not be restored");
		if (restored != 0) return;

		// Restoring can finish after the verb returns
		var end = Sys.time() + 5;
		while (!FileSystem.exists(path) && Sys.time() < end) Sys.sleep(0.05);
		Assert.isTrue(FileSystem.exists(path), name + " was not restored where it was");
		if (FileSystem.exists(path)) remove(path);
		#else
		var trash = #if mac Path.join([Sys.getEnv("HOME"), ".Trash"]) #else Path.join([
			Sys.getEnv("XDG_DATA_HOME") != null && Sys.getEnv("XDG_DATA_HOME") != "" ? Sys.getEnv("XDG_DATA_HOME") : Path.join([Sys.getEnv("HOME"), ".local", "share"]),
			"Trash", "files"
		]) #end;
		var trashed = Path.join([trash, name]);
		Assert.isTrue(FileSystem.exists(trashed), name + " is not in " + trash);
		if (FileSystem.exists(trashed)) remove(trashed);

		#if linux
		var info = Path.join([Path.directory(trash), "info", name + ".trashinfo"]);
		if (FileSystem.exists(info)) FileSystem.deleteFile(info);
		#end
		#end
	}

	private static function newFile(name:String):String
	{
		var file = Path.join([temporaryFolder(), name]);
		File.saveContent(file, "text");
		return file;
	}

	private static function remove(path:String):Void
	{
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
		Runs a PowerShell script, and returns its exit code.
	**/
	private static function powerShell(script:String):Int
	{
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
		var exitCode = process.exitCode();
		process.close();
		return exitCode;
	}
	#end
	#else
	public function testNothingCanBeMovedToTheTrash():Void
	{
		// Web and Flash have no files of their own to move
		Assert.isFalse(System.moveToTrash("file.txt"));
	}
	#end
}
