import hxp.Path;
import hxp.System;
import sys.io.Process;
import utest.Assert;
import utest.Test;

/**
	What `lime run` passes to the application at launch: the arguments that follow `-args`,
	`--args` or `--` (#1746), before those the tools add of their own, such as `-verbose`. The tools
	read their own command line, so this program is started again as them, in `-dryrun`, and the
	arguments are read from the command it would run.
**/
class LaunchArgumentsTest extends Test
{
	/** The variable that starts this program as the command-line tools **/
	public static inline var RUN_TOOLS = "LIME_TOOLS_TESTS_RUN_TOOLS";

	private var fixture:Fixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
		fixture.write("project.xml", '<project>
			<meta title="Launch Arguments" />
			<app main="Main" file="LaunchArguments" path="Export" />
		</project>');
		fixture.write("Main.hx", "class Main {}");

		// The application's folder, which a run starts it in
		runTools(["update", target(), "-dryrun"]);
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	public function testTheArgumentsAfterArgsReachTheApplication():Void
	{
		var own = launchArguments([]);
		if (own == null) return;

		Fixture.assertSame(["a", "b"].concat(own), launchArguments(["-args", "a", "b"]));
		Fixture.assertSame(["a", "b"].concat(own), launchArguments(["--args", "a", "b"]));
		Fixture.assertSame(["a", "b"].concat(own), launchArguments(["--", "a", "b"]));
	}

	// --args=value is a setting of the tools' own, as any --name=value is, and the flags after it
	// are theirs too
	public function testArgsWithAValueStartsNoLaunchArguments():Void
	{
		var own = launchArguments([]);
		if (own == null) return;

		Fixture.assertSame(own, launchArguments(["--args=value"]));
		Fixture.assertSame(own, launchArguments(["--args=value", "-Dlaunch-marker"]));
	}

	/**
		The arguments that the application would be started with, or null when the tools would
		start none.
	**/
	private function launchArguments(arguments:Array<String>):Array<String>
	{
		var output = runTools(["run", target(), "-dryrun", "-verbose", "-nocolor"].concat(arguments));
		var command = ~/Running command: ([^\r\n]*LaunchArguments[^ \r\n]*)([^\r\n]*)/;

		if (!command.match(output))
		{
			Assert.fail("the tools started no application: " + output);
			return null;
		}

		return [for (argument in StringTools.trim(command.matched(2)).split(" ")) if (argument != "") argument];
	}

	/**
		Runs the tools on the fixture's project, as `haxelib run lime` does with Lime's folder as the
		working directory and the project's last, and gives what they printed.
	**/
	private function runTools(arguments:Array<String>):String
	{
		var program = Path.combine(LimeRepo.path(), "tests/tools/bin/tools-tests.n");
		var previousConfig = Sys.getEnv("LIME_CONFIG");
		var cwd = Sys.getCwd();

		Sys.putEnv(RUN_TOOLS, "1");
		// A config of the fixture's own, which isn't there, rather than the user's
		Sys.putEnv("LIME_CONFIG", Path.combine(fixture.directory, "config.xml"));
		Sys.setCwd(LimeRepo.path());

		var output = "";

		try
		{
			var process = new Process("neko", [program, "--haxelib-lime=" + LimeRepo.path()].concat(arguments).concat([fixture.directory]));
			output = process.stdout.readAll().toString() + process.stderr.readAll().toString();
			process.exitCode();
			process.close();
		}
		catch (e:Dynamic)
		{
			output = "the tools could not be started: " + e;
		}

		Sys.setCwd(cwd);
		Sys.putEnv("LIME_CONFIG", previousConfig);
		Sys.putEnv(RUN_TOOLS, null);

		return output;
	}

	/** The desktop target of the machine the tests run on, as it builds for itself **/
	private static function target():String
	{
		return switch (System.hostPlatform)
		{
			case WINDOWS: "windows";
			case MAC: "mac";
			default: "linux";
		}
	}
}
