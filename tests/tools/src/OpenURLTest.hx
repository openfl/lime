import haxe.Timer;
import hxp.Path;
import hxp.System;
import lime.tools.CommandHelper;
import sys.FileSystem;
import sys.io.File;
import utest.Assert;
import utest.Test;

/**
	`CommandHelper.openURL()`, which `lime test html5` uses to open the page it serves.

	On Linux it runs xdg-open. Here xdg-open is a script put first on the `PATH` that
	writes down its arguments and then takes a few seconds to exit, as xdg-open does when
	it starts a browser.
**/
class OpenURLTest extends Test
{
	private static inline var URL:String = "http://127.0.0.1:3000/?a=1&b='two words'";

	private var fixture:Fixture;
	private var previousPath:String;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
		previousPath = Sys.getEnv("PATH");
	}

	public function teardown():Void
	{
		Sys.putEnv("PATH", previousPath);
		fixture.dispose();
	}

	public function testXdgOpenGetsTheURLAsItsOnlyArgument():Void
	{
		if (System.hostPlatform != LINUX)
		{
			Assert.pass("xdg-open is only used on Linux");
			return;
		}

		var arguments = installXdgOpen();

		CommandHelper.openURL(URL);

		Assert.equals("1\n" + URL + "\n", waitForContent(arguments));
	}

	public function testOpeningDoesNotWaitForXdgOpen():Void
	{
		if (System.hostPlatform != LINUX)
		{
			Assert.pass("xdg-open is only used on Linux");
			return;
		}

		installXdgOpen();

		var start = Timer.stamp();
		CommandHelper.openURL(URL);
		var elapsed = Timer.stamp() - start;

		Assert.isTrue(elapsed < 2, "openURL() took " + elapsed + " s, while xdg-open takes 5 s to exit");
	}

	/**
		Puts a stand-in xdg-open first on the `PATH`. Returns the file it writes its
		argument count and arguments to, one per line.
	**/
	private function installXdgOpen():String
	{
		var arguments = Path.combine(fixture.directory, "arguments");
		var script = fixture.write("bin/xdg-open", "#!/bin/sh\nprintf '%s\\n' \"$#\" \"$@\" > '" + arguments + ".tmp'\nmv '" + arguments + ".tmp' '"
			+ arguments + "'\nsleep 5\n");
		Sys.command("chmod", ["+x", script]);
		Sys.putEnv("PATH", Path.directory(script) + ":" + previousPath);
		return arguments;
	}

	private static function waitForContent(path:String):String
	{
		var start = Timer.stamp();

		while (!FileSystem.exists(path) && Timer.stamp() - start < 4)
		{
			Sys.sleep(0.05);
		}

		return FileSystem.exists(path) ? File.getContent(path) : null;
	}
}
