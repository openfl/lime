package system;

import utest.Assert;
import utest.Test;

/**
	Lime builds the HashLink runtime it ships, so processes have to start from
	it as they do from HashLink's own builds.
**/
class ProcessTest extends Test
{
	public function new()
	{
		super();
	}

	#if (sys && !macro)
	public function testAProcessStartsAndGivesItsOutputAndExitCode():Void
	{
		var found = run(["cmd"]);
		Assert.notNull(found, "the process did not start");
		if (found == null) return;

		Assert.equals(0, found.exitCode);
		Assert.isTrue(found.output.length > 0, "the process wrote nothing");

		var missing = run(["lime-no-such-program"]);
		Assert.notNull(missing, "the process did not start");
		if (missing != null) Assert.notEquals(0, missing.exitCode);
	}

	/**
		Looks programs up with where on Windows and which elsewhere, which are
		found by their paths and need no shell.
	**/
	private static function run(arguments:Array<String>):{output:String, exitCode:Int}
	{
		#if windows
		var root = Sys.getEnv("SystemRoot");
		var executable = (root != null ? root : "C:\\Windows") + "\\System32\\where.exe";
		#else
		var executable = sys.FileSystem.exists("/usr/bin/which") ? "/usr/bin/which" : "which";
		if (arguments[0] == "cmd") arguments = ["sh"];
		#end

		try
		{
			var process = new sys.io.Process(executable, arguments);
			var output = process.stdout.readAll().toString();
			process.stderr.readAll();
			var exitCode = process.exitCode();
			process.close();
			return {output: output, exitCode: exitCode};
		}
		catch (e:Dynamic)
		{
			trace("Process creation failed: " + e);
			return null;
		}
	}
	#end
}
