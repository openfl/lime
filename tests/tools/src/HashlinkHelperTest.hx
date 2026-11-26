import haxe.io.Bytes;
import hxp.Log;
import hxp.Path;
import lime.tools.ConfigHelper;
import lime.tools.HashlinkHelper;
import lime.tools.HXProject;
import sys.FileSystem;
import sys.io.File;
import utest.Assert;
import utest.Test;

/**
	A Windows HashLink build's launcher is hl.exe, copied and renamed. A release build marks it a GUI
	application, so no console opens with it, while a debug build keeps it a console application, so
	traces and uncaught errors reach the terminal it runs from (#2449). `SHOW_CONSOLE` keeps the console
	in a release build too.

	The launcher here is a stand-in: an executable with a PE header and nothing else, given to the tools
	through `HL_PATH` in a Lime config of the test's own, so no HashLink runtime is needed. Its subsystem
	is the optional header's field at offset 68 (PE format, Microsoft): 2 is a GUI application and 3 a
	console one.
**/
class HashlinkHelperTest extends Test
{
	private static inline var PE_OFFSET = 0x80;
	private static inline var SUBSYSTEM_OFFSET = PE_OFFSET + 24 + 68;
	private static inline var WINDOWS_GUI = 2;
	private static inline var WINDOWS_CUI = 3;

	private var fixture:Fixture;
	private var configPath:String;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
		fixture.target = WINDOWS;

		var hl = Path.combine(fixture.directory, "hl");
		FileSystem.createDirectory(hl);
		File.saveBytes(Path.combine(hl, "hl.exe"), consoleExecutable());
		File.saveContent(Path.combine(hl, "libhl.dll"), "");

		var config = fixture.write("config.xml", '<project><define name="HL_PATH" value="' + hl + '" /></project>');
		configPath = @:privateAccess ConfigHelper.configPath;
		@:privateAccess ConfigHelper.configPath = config;
	}

	public function teardown():Void
	{
		@:privateAccess ConfigHelper.configPath = configPath;
		fixture.dispose();
	}

	public function testAReleaseBuildsLauncherIsAGUIApplication():Void
	{
		Assert.equals(WINDOWS_GUI, launcherSubsystem(false, false));
	}

	public function testADebugBuildsLauncherKeepsItsConsole():Void
	{
		Assert.equals(WINDOWS_CUI, launcherSubsystem(true, false));
	}

	public function testShowConsoleKeepsTheConsoleInAReleaseBuild():Void
	{
		Assert.equals(WINDOWS_CUI, launcherSubsystem(false, true));
	}

	/** Copies the stand-in hl.exe as the tools do for a build, and reads the copy's subsystem **/
	private function launcherSubsystem(debug:Bool, showConsole:Bool):Int
	{
		var project:HXProject = fixture.parse("<project />");
		project.debug = debug;
		if (showConsole) project.environment.set("SHOW_CONSOLE", "1");

		var targetDirectory = Path.combine(fixture.directory, "bin/hl");
		var applicationDirectory = Path.combine(targetDirectory, "bin");
		var executablePath = Path.combine(applicationDirectory, "Application.exe");
		FileSystem.createDirectory(applicationDirectory);
		// The compiled application, which is copied beside the launcher as hlboot.dat
		fixture.write("bin/hl/obj/ApplicationMain.hl", "");

		var mute = Log.mute;
		Log.mute = true;
		HashlinkHelper.copyHashlink(project, targetDirectory, applicationDirectory, executablePath, true);
		Log.mute = mute;

		if (!FileSystem.exists(executablePath))
		{
			Assert.fail("the launcher was not copied");
			return -1;
		}

		var bytes = File.getBytes(executablePath);
		return bytes.get(SUBSYSTEM_OFFSET) | (bytes.get(SUBSYSTEM_OFFSET + 1) << 8);
	}

	/** The smallest executable the tools take: a DOS header pointing at a PE header for a console application **/
	private static function consoleExecutable():Bytes
	{
		var bytes = Bytes.alloc(0x200);
		bytes.fill(0, bytes.length, 0);
		bytes.set(0, "M".code);
		bytes.set(1, "Z".code);
		bytes.setInt32(0x3C, PE_OFFSET);
		bytes.set(PE_OFFSET, "P".code);
		bytes.set(PE_OFFSET + 1, "E".code);
		bytes.set(SUBSYSTEM_OFFSET, WINDOWS_CUI);
		return bytes;
	}
}
