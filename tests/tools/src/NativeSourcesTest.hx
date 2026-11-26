import hxp.Path;
import hxp.System;
import lime.tools.NativeSourcesHelper;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import utest.Assert;
import utest.Test;

/**
	What `lime rebuild` records beside the native libraries of a git checkout, and the warnings
	builds give from it, from the 8.4.0 changelog:

	`lime rebuild` records what each native library it builds in a git checkout was built
	from (the git tree of `project` and the submodule commits) beside it. A native build warns
	when a library it uses was built from older native sources than the checkout has, naming
	`lime rebuild <target>`, and `lime rebuild` warns when submodules are not at the commits
	the checkout pins, naming `git submodule update --init --recursive`. Haxelib releases (no
	`.git`) and libraries without a record are not checked.

	Each test makes a library that is a git repository with `project/Build.xml` and an `ndll`
	folder. Its "rebuild" writes library files the way hxcpp does: it leaves a file alone
	while the hash hxcpp keeps beside it is there.
**/
class NativeSourcesTest extends Test
{
	private var library:GitLibrary;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		library = new GitLibrary("lime");
	}

	public function teardown():Void
	{
		library.dispose();
	}

	public function testRebuildRecordsTheSourcesBesideEachLibraryItBuilds():Void
	{
		library.rebuild(["Windows64/lime.ndll", "Windows64/lime.hdll"]);

		Assert.isTrue(FileSystem.exists(library.path("ndll/Windows64/lime.ndll" + NativeSourcesHelper.RECORD_EXTENSION)));
		Assert.isTrue(FileSystem.exists(library.path("ndll/Windows64/lime.hdll" + NativeSourcesHelper.RECORD_EXTENSION)));

		var record = NativeSourcesHelper.readRecord(library.path("ndll/Windows64/lime.ndll"));
		Assert.notNull(record);
		Assert.equals("project", record.source);
		Assert.equals(library.git(["rev-parse", "HEAD:project"]), record.tree);
		Assert.equals(library.git(["rev-parse", "HEAD"]), record.commit);
		Assert.equals(0, record.submodules.length);
	}

	public function testLibraryBuiltFromTheCheckoutIsCurrent():Void
	{
		library.rebuild(["Windows64/lime.ndll"]);

		Fixture.assertSame([], NativeSourcesHelper.getChanges(library.path("ndll/Windows64/lime.ndll")));
		Assert.isNull(NativeSourcesHelper.getStaleMessage(library.path("ndll/Windows64/lime.ndll")));
	}

	public function testLibraryIsStaleAfterACommitChangesTheNativeSources():Void
	{
		library.rebuild(["Windows64/lime.ndll"]);
		library.commit("project/src/Code.cpp", "int changed;");

		var path = library.path("ndll/Windows64/lime.ndll");
		Fixture.assertSame(["project"], NativeSourcesHelper.getChanges(path));

		var message = NativeSourcesHelper.getStaleMessage(path);
		Assert.notNull(message);
		Assert.stringContains("lime.ndll", message);
		Assert.stringContains("older native sources", message);
		Assert.stringContains("lime rebuild windows", message);
	}

	// A pull that has not been committed to is a change of HEAD too, so this is the same as a pull
	public function testLibraryIsStaleAfterAnotherCommitIsCheckedOut():Void
	{
		library.commit("project/src/Code.cpp", "int newer;");
		library.git(["checkout", "-q", "HEAD~1"]);
		library.rebuild(["Windows64/lime.ndll"]);
		library.git(["checkout", "-q", "main"]);

		Assert.notNull(NativeSourcesHelper.getStaleMessage(library.path("ndll/Windows64/lime.ndll")));
	}

	public function testCommitOutsideTheNativeSourcesLeavesTheLibraryCurrent():Void
	{
		library.rebuild(["Windows64/lime.ndll"]);
		library.commit("README.md", "Changed");
		library.commit("src/lime/Code.hx", "class Code {}");

		Fixture.assertSame([], NativeSourcesHelper.getChanges(library.path("ndll/Windows64/lime.ndll")));
	}

	public function testDebugLibraryNamesTheDebugRebuild():Void
	{
		library.rebuild(["Windows64/lime-debug.ndll"]);
		library.commit("project/src/Code.cpp", "int changed;");

		Assert.stringContains("lime rebuild windows -debug", NativeSourcesHelper.getStaleMessage(library.path("ndll/Windows64/lime-debug.ndll")));
	}

	public function testHashLinkLibraryNamesTheHashLinkRebuild():Void
	{
		library.rebuild(["Windows64/lime.hdll"]);
		library.commit("project/src/Code.cpp", "int changed;");

		Assert.stringContains("lime rebuild hl", NativeSourcesHelper.getStaleMessage(library.path("ndll/Windows64/lime.hdll")));
	}

	public function testRebuildOfAnotherLibraryNamesTheLibrary():Void
	{
		var extension = new GitLibrary("toolstest-extension");

		try
		{
			extension.rebuild(["Android/libtoolstest-extension-64.so"]);
			extension.commit("project/src/Code.cpp", "int changed;");

			Assert.stringContains("lime rebuild toolstest-extension android",
				NativeSourcesHelper.getStaleMessage(extension.path("ndll/Android/libtoolstest-extension-64.so")));
		}
		catch (e:Dynamic)
		{
			extension.dispose();
			throw e;
		}

		extension.dispose();
	}

	// hxcpp leaves a library alone when nothing it is linked from has changed, as after a
	// commit that changes only code for another platform. lime rebuild still has to record it.
	public function testRebuildRecordsALibraryThatHxcppWouldLeaveUpToDate():Void
	{
		library.rebuild(["Windows64/lime.ndll"]);
		library.commit("project/src/ios/Code.mm", "int iosOnly;");

		library.rebuild(["Windows64/lime.ndll"]);

		Fixture.assertSame([], NativeSourcesHelper.getChanges(library.path("ndll/Windows64/lime.ndll")));
	}

	// lime rebuild windows runs hxcpp once for each architecture
	public function testRebuildForEachArchitectureRecordsEachLibrary():Void
	{
		library.rebuild(["Windows/lime.ndll", "Windows64/lime.ndll"]);
		library.commit("project/src/Code.cpp", "int changed;");

		library.rebuild(["Windows/lime.ndll"]);
		library.rebuild(["Windows64/lime.ndll"]);

		Fixture.assertSame([], NativeSourcesHelper.getChanges(library.path("ndll/Windows/lime.ndll")));
		Fixture.assertSame([], NativeSourcesHelper.getChanges(library.path("ndll/Windows64/lime.ndll")));
	}

	public function testRebuildWithoutChangesLeavesTheLibrariesAlone():Void
	{
		library.rebuild(["Windows64/lime.ndll"]);
		var built = File.getContent(library.path("ndll/Windows64/lime.ndll"));

		library.rebuild(["Windows64/lime.ndll"]);

		Assert.equals(built, File.getContent(library.path("ndll/Windows64/lime.ndll")));
		Assert.isTrue(FileSystem.exists(library.path("ndll/Windows64/lime.ndll.hash")));
	}

	public function testRebuildLeavesTheRecordsOfLibrariesItDidNotBuild():Void
	{
		library.rebuild(["Windows64/lime.ndll", "Linux64/lime.ndll"]);
		library.commit("project/src/Code.cpp", "int changed;");

		library.rebuild(["Windows64/lime.ndll"]);

		Fixture.assertSame([], NativeSourcesHelper.getChanges(library.path("ndll/Windows64/lime.ndll")));

		var message = NativeSourcesHelper.getStaleMessage(library.path("ndll/Linux64/lime.ndll"));
		Assert.notNull(message);
		Assert.stringContains("lime rebuild linux", message);
	}

	public function testLibraryWithoutARecordIsNotChecked():Void
	{
		library.write("ndll/Windows64/lime.ndll", "built before records");
		library.commit("project/src/Code.cpp", "int changed;");

		Assert.isNull(NativeSourcesHelper.getChanges(library.path("ndll/Windows64/lime.ndll")));
		Assert.isNull(NativeSourcesHelper.getStaleMessage(library.path("ndll/Windows64/lime.ndll")));
	}

	// A haxelib release has no .git, even with records from the build that made it
	public function testLibraryOutsideAGitCheckoutIsNotChecked():Void
	{
		var release = library.path("../" + Path.withoutDirectory(library.root) + "-release");
		GitLibrary.writeFile(release + "/haxelib.json", '{"name": "lime"}');
		GitLibrary.writeFile(release + "/project/Build.xml", "<xml />");
		GitLibrary.writeFile(release + "/ndll/Windows64/lime.ndll", "released");
		GitLibrary.writeFile(release + "/ndll/Windows64/lime.ndll" + NativeSourcesHelper.RECORD_EXTENSION,
			"commit 1111111111111111111111111111111111111111\nsource project\ntree 2222222222222222222222222222222222222222\n");

		Assert.isNull(NativeSourcesHelper.getChanges(release + "/ndll/Windows64/lime.ndll"));
		Assert.isNull(NativeSourcesHelper.getStaleMessage(release + "/ndll/Windows64/lime.ndll"));

		GitLibrary.removeDirectory(release);
	}

	public function testRebuildOutsideAGitCheckoutRecordsNothing():Void
	{
		var release = library.path("../" + Path.withoutDirectory(library.root) + "-release");
		GitLibrary.writeFile(release + "/project/Build.xml", "<xml />");

		NativeSourcesHelper.rebuild(release + "/project", function()
		{
			GitLibrary.writeFile(release + "/ndll/Windows64/lime.ndll", "built");
		});

		Assert.isTrue(FileSystem.exists(release + "/ndll/Windows64/lime.ndll"));
		Assert.isFalse(FileSystem.exists(release + "/ndll/Windows64/lime.ndll" + NativeSourcesHelper.RECORD_EXTENSION));

		GitLibrary.removeDirectory(release);
	}

	public function testDryRunRecordsNothing():Void
	{
		System.dryRun = true;

		try
		{
			library.rebuild(["Windows64/lime.ndll"]);
		}
		catch (e:Dynamic)
		{
			System.dryRun = false;
			throw e;
		}

		System.dryRun = false;

		Assert.isFalse(FileSystem.exists(library.path("ndll/Windows64/lime.ndll" + NativeSourcesHelper.RECORD_EXTENSION)));
	}

	public function testSubmoduleThatMovesMakesTheLibraryStale():Void
	{
		library.addSubmodule("project/lib/zlib");
		library.rebuild(["Windows64/lime.ndll"]);

		library.moveSubmodule("project/lib/zlib");

		var path = library.path("ndll/Windows64/lime.ndll");
		Fixture.assertSame(["project/lib/zlib"], NativeSourcesHelper.getChanges(path));
		Assert.stringContains("project/lib/zlib", NativeSourcesHelper.getStaleMessage(path));
	}

	public function testRebuildRecordsTheCommitOfASubmoduleThatIsNotAtItsPin():Void
	{
		library.addSubmodule("project/lib/zlib");
		var pinned = library.git(["-C", "project/lib/zlib", "rev-parse", "HEAD"]);
		library.moveSubmodule("project/lib/zlib");
		var moved = library.git(["-C", "project/lib/zlib", "rev-parse", "HEAD"]);

		library.rebuild(["Windows64/lime.ndll"]);

		var path = library.path("ndll/Windows64/lime.ndll");
		var record = NativeSourcesHelper.readRecord(path);
		Assert.equals(1, record.submodules.length);
		Assert.equals("project/lib/zlib", record.submodules[0].path);
		Assert.equals(moved, record.submodules[0].commit);
		Fixture.assertSame([], NativeSourcesHelper.getChanges(path));

		// git submodule update puts it back at its pin, which the library was not built from
		library.git(["-C", "project/lib/zlib", "checkout", "-q", pinned]);
		Fixture.assertSame(["project/lib/zlib"], NativeSourcesHelper.getChanges(path));
	}

	public function testSubmodulesAtTheirPinsAreNotReported():Void
	{
		library.addSubmodule("project/lib/zlib");

		Assert.isNull(NativeSourcesHelper.getSubmoduleMessage(library.root));
	}

	public function testSubmoduleAtAnotherCommitIsReported():Void
	{
		library.addSubmodule("project/lib/zlib");
		library.addSubmodule("project/lib/png");
		library.moveSubmodule("project/lib/zlib");

		var message = NativeSourcesHelper.getSubmoduleMessage(library.root);
		Assert.notNull(message);
		Assert.stringContains("project/lib/zlib (at another commit)", message);
		Assert.isFalse(message.indexOf("project/lib/png") > -1);
		Assert.stringContains("git submodule update --init --recursive", message);
	}

	public function testSubmoduleNotCheckedOutIsReported():Void
	{
		library.addSubmodule("project/lib/zlib");
		library.git(["submodule", "deinit", "-q", "-f", "project/lib/zlib"]);

		var message = NativeSourcesHelper.getSubmoduleMessage(library.root);
		Assert.notNull(message);
		Assert.stringContains("project/lib/zlib (not checked out)", message);
		Assert.stringContains("git submodule update --init --recursive", message);
	}

	// From git's documentation of "git submodule status"
	public function testSubmoduleStatusLinesAreRead():Void
	{
		var status = NativeSourcesHelper.parseSubmoduleStatus(" 200441e6855854eb4dbf338e44d67b00ababe07f project/lib/cairo (200441e68)\n"
			+ "+8f27f9428e0f64e9ae9ea53490e87a862c6a8211 project/lib/zlib (8f27f94)\r\n"
			+ "-3163ec065643ba20709f190111f42c3e1fe95273 project/lib/curl\n"
			+ "U0000000000000000000000000000000000000000 project/lib/sdl\n");

		Assert.equals(4, status.length);
		Assert.equals(" ", status[0].state);
		Assert.equals("project/lib/cairo", status[0].path);
		Assert.equals("200441e6855854eb4dbf338e44d67b00ababe07f", status[0].commit);
		Assert.equals("+", status[1].state);
		Assert.equals("project/lib/zlib", status[1].path);
		Assert.equals("-", status[2].state);
		Assert.equals("project/lib/curl", status[2].path);
		Assert.equals("U", status[3].state);
	}

	public function testFoldersNameTheirRebuildTargets():Void
	{
		Assert.equals("windows", NativeSourcesHelper.getTargetName("Windows", "ndll"));
		Assert.equals("windows", NativeSourcesHelper.getTargetName("Windows64", "ndll"));
		Assert.equals("windows", NativeSourcesHelper.getTargetName("WindowsArm64", "lib"));
		Assert.equals("winrt", NativeSourcesHelper.getTargetName("WinRT64", "ndll"));
		Assert.equals("hl", NativeSourcesHelper.getTargetName("Windows64", "hdll"));
		Assert.equals("linux", NativeSourcesHelper.getTargetName("LinuxArm64", "ndll"));
		Assert.equals("mac", NativeSourcesHelper.getTargetName("MacArm64", "ndll"));
		Assert.equals("android", NativeSourcesHelper.getTargetName("Android", "so"));
		Assert.equals("ios", NativeSourcesHelper.getTargetName("iPhone", "a"));
		Assert.equals("tvos", NativeSourcesHelper.getTargetName("AppleTV", "a"));
		Assert.equals("webassembly", NativeSourcesHelper.getTargetName("Emscripten", "a"));
	}
}

/**
	A library that is a git repository in the system's temporary directory.
**/
private class GitLibrary
{
	private static var nextID = 0;

	public var root(default, null):String;

	private var builds = 0;
	private var submodules:Array<String>;

	public function new(name:String)
	{
		var temp = Sys.getEnv(Sys.systemName() == "Windows" ? "TEMP" : "TMPDIR");
		if (temp == null || temp == "") temp = "/tmp";

		root = Path.combine(Path.standardize(temp), "lime-native-sources-test-" + Std.random(0x3FFFFFFF) + "-" + (nextID++));
		submodules = [];

		write("haxelib.json", '{"name": "$name", "version": "1.0.0"}');
		write("README.md", "Library");
		write("project/Build.xml", "<xml />");
		write("project/src/Code.cpp", "int code;");

		git(["init", "-q", "-b", "main"]);
		git(["add", "-A"]);
		git(["commit", "-q", "-m", "Library"]);
	}

	public function addSubmodule(relative:String):Void
	{
		var repository = root + "-submodule-" + submodules.length;
		submodules.push(repository);

		writeFile(repository + "/file.c", "int file;");
		run(repository, ["init", "-q", "-b", "main"]);
		run(repository, ["add", "-A"]);
		run(repository, ["commit", "-q", "-m", "Submodule"]);

		git(["-c", "protocol.file.allow=always", "submodule", "add", "-q", repository, relative]);
		git(["commit", "-q", "-m", "Add " + relative]);
	}

	// What a submodule left at an older commit, or moved by hand, looks like
	public function moveSubmodule(relative:String):Void
	{
		run(path(relative), ["commit", "-q", "--allow-empty", "-m", "Moved"]);
	}

	public function commit(relative:String, content:String):Void
	{
		write(relative, content);
		git(["add", "-A"]);
		git(["commit", "-q", "-m", "Change " + relative]);
	}

	public function dispose():Void
	{
		removeDirectory(root);

		for (repository in submodules)
		{
			removeDirectory(repository);
		}
	}

	public function git(args:Array<String>):String
	{
		return run(root, args);
	}

	public function path(relative:String):String
	{
		return Path.combine(root, relative);
	}

	/**
		Rebuilds through `NativeSourcesHelper.rebuild()`. Like hxcpp, the build writes a library
		file and its hash only when the hash is missing.
	**/
	public function rebuild(files:Array<String>):Void
	{
		NativeSourcesHelper.rebuild(path("project"), function()
		{
			builds++;

			for (file in files)
			{
				var output = path("ndll/" + file);
				if (FileSystem.exists(output + ".hash")) continue;

				writeFile(output, "build " + builds);
				writeFile(output + ".hash", "hash");
			}
		});
	}

	public function write(relative:String, content:String):Void
	{
		writeFile(path(relative), content);
	}

	public static function removeDirectory(path:String):Void
	{
		if (!FileSystem.exists(path)) return;

		// git makes its objects read-only, which FileSystem.deleteFile cannot remove on Windows
		if (Sys.systemName() == "Windows")
		{
			Sys.command("cmd", ["/c", "rmdir", "/s", "/q", StringTools.replace(path, "/", "\\")]);
		}
		else
		{
			Sys.command("rm", ["-rf", path]);
		}
	}

	public static function writeFile(path:String, content:String):Void
	{
		System.mkdir(Path.directory(path));
		File.saveContent(path, content);
	}

	private static function run(directory:String, args:Array<String>):String
	{
		var process = new Process("git", [
			"-C", directory,
			"-c", "user.name=Lime Tests",
			"-c", "user.email=tests@example.com",
			"-c", "commit.gpgsign=false",
			"-c", "core.autocrlf=false"
		].concat(args));

		var output = process.stdout.readAll().toString();
		var errors = process.stderr.readAll().toString();
		var exitCode = process.exitCode();
		process.close();

		if (exitCode != 0)
		{
			throw "git " + args.join(" ") + " failed: " + errors;
		}

		return StringTools.trim(output);
	}
}
