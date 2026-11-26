import hxp.Haxelib;
import hxp.Path;
import lime.tools.CPPHelper;
import lime.tools.HXProject;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import utest.Assert;
import utest.Test;

/**
	Which hxcpp `CPPHelper.compile()` runs, through `haxelib run hxcpp` in the build folder. haxelib
	looks for a project's own repository, a .haxelib folder, from the folder it runs in and those
	above it, so a build folder outside the project ran the hxcpp of the global repository instead
	(#1677). The build now runs with HAXELIB_PATH set to the repository the project has.

	These run the real haxelib, with a project whose .haxelib holds a stand-in hxcpp and a global
	repository, set as HAXELIB_PATH, that holds another, each of which writes down that it ran.
**/
class CPPHelperTest extends Test
{
	private static inline var LOG = "LIME_TOOLS_TESTS_HXCPP_LOG";

	private var fixture:Fixture;
	private var globalRepository:String;
	private var log:String;
	private var project:String;
	private var ready:Bool;

	// What the tests change, which they put back
	private var environment:Map<String, Null<String>>;
	private var repositoryPath:String;
	private var workingDirectory:String;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
		project = Path.combine(fixture.directory, "project");
		globalRepository = Path.combine(fixture.directory, "global");
		log = Path.combine(fixture.directory, "hxcpp.log");

		environment = [for (name in ["HAXELIB_PATH", LOG, "HXCPP_COMPILE_THREADS", "HXCPP_EXIT_ON_ERROR", "HXCPP_NO_COLOR"]) name => Sys.getEnv(name)];
		repositoryPath = @:privateAccess Haxelib.repositoryPath;
		workingDirectory = Haxelib.workingDirectory;

		ready = writeStandIns();
	}

	public function teardown():Void
	{
		for (name in environment.keys())
		{
			Sys.putEnv(name, environment.get(name));
		}

		@:privateAccess Haxelib.repositoryPath = repositoryPath;
		Haxelib.workingDirectory = workingDirectory;
		fixture.dispose();
	}

	public function testTheProjectsHxcppRunsForABuildFolderOutsideTheProject():Void
	{
		if (!ready) return;

		Assert.equals("local", compile(Path.combine(fixture.directory, "build")));
	}

	public function testTheProjectsHxcppRunsForABuildFolderInsideTheProject():Void
	{
		if (!ready) return;

		Assert.equals("local", compile(Path.combine(project, "Export/windows/obj")));
	}

	public function testHaxelibPathIsGivenBackAfterwards():Void
	{
		if (!ready) return;

		compile(Path.combine(fixture.directory, "build"));
		Assert.equals(globalRepository, Sys.getEnv("HAXELIB_PATH"));
	}

	/**
		Compiles in `buildFolder` as the tools do for the project, from the project's folder, and
		gives which hxcpp ran: "local", "global", or what else was written down.
	**/
	private function compile(buildFolder:String):String
	{
		FileSystem.createDirectory(buildFolder);

		Sys.putEnv("HAXELIB_PATH", globalRepository);
		Sys.putEnv(LOG, log);
		@:privateAccess Haxelib.repositoryPath = null;
		Haxelib.workingDirectory = project;

		var parsed:HXProject = fixture.parse("<project />");
		CPPHelper.compile(parsed, buildFolder);

		return FileSystem.exists(log) ? StringTools.trim(File.getContent(log)) : "nothing";
	}

	/**
		Writes the project's repository and the global one, each with an hxcpp that writes its name
		to the file LIME_TOOLS_TESTS_HXCPP_LOG names. Returns whether haxelib and the Haxe compiler
		that makes them are here to run, passing the test, saying why, when they aren't.
	**/
	private function writeStandIns():Bool
	{
		fixture.write("stand-in/StandIn.hx", "class StandIn {
	static function main() {
		// haxelib runs a library in its own folder
		var out = sys.io.File.append(Sys.getEnv(\"" + LOG + "\"), false);
		out.writeString(sys.io.File.getContent(\"label.txt\"));
		out.close();
	}
}");

		var run = Path.combine(fixture.directory, "stand-in/run.n");

		if (!succeeds("haxe", ["-cp", Path.combine(fixture.directory, "stand-in"), "-main", "StandIn", "-neko", run]) || !succeeds("haxelib", ["version"]))
		{
			trace("haxelib or the Haxe compiler can't run here, so which hxcpp a build runs was not tested");
			Assert.pass();
			return false;
		}

		for (name in ["local", "global"])
		{
			var folder = "hxcpp-" + name;
			fixture.write(folder + "/haxelib.json", '{"name": "hxcpp", "version": "1.0.0", "license": "MIT"}');
			fixture.write(folder + "/label.txt", name);
			File.copy(run, Path.combine(fixture.directory, folder + "/run.n"));
		}

		fixture.write("project/.haxelib/hxcpp/.dev", Path.combine(fixture.directory, "hxcpp-local"));
		fixture.write("global/hxcpp/.dev", Path.combine(fixture.directory, "hxcpp-global"));
		return true;
	}

	private static function succeeds(command:String, arguments:Array<String>):Bool
	{
		try
		{
			var process = new Process(command, arguments);
			process.stdout.readAll();
			process.stderr.readAll();
			var code = process.exitCode();
			process.close();
			return code == 0;
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}
}
