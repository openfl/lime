import hxp.Haxelib;
import hxp.Log;
import hxp.Path;
import hxp.System;
import lime.tools.HTML5Helper;
import lime.tools.HXProject;
import sys.FileSystem;
import utest.Assert;
import utest.Test;

/**
	The tools warn about what Lime 9 removes (8.4.0 changelog): the armv5 and armv6 architectures on
	Android, whose armeabi the Android NDK dropped in r17, and the YUI Compressor, `-yui`. Neither is
	warned about where it isn't used: armv7 and arm64 alone, `-minify` without `-yui`, or `display`, which
	an IDE reads as build arguments, and `clean`.

	A warning is read from what hxp's Log keeps of each one it prints, so the log is not muted while
	they run, and each test forgets the warnings first. Haxe 3's warning comes from running `haxe
	-version`, which these tests can't answer with another version.
**/
class LimeNineWarningTest extends Test
{
	private static inline var ARMEABI = "The armv5 and armv6 architectures (armeabi) are deprecated on Android, and Lime 9 removes them. The Android NDK dropped armeabi in r17, so build armv7 or arm64 instead.";
	private static inline var YUI = "The YUI Compressor (-yui) is deprecated, and Lime 9 removes it. Minify with -minify alone, which uses the Google Closure Compiler, or with -minify -terser.";

	private var fixture:Fixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
		forget(ARMEABI);
		forget(YUI);
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	public function testArmv5AndArmv6AreWarnedAbout():Void
	{
		for (architecture in ["armv5", "armv6"])
		{
			forget(ARMEABI);
			android('<project><architecture name="$architecture" /></project>', "update");
			Assert.isTrue(warned(ARMEABI), architecture);
		}
	}

	public function testArmv7AndArm64AreNotWarnedAbout():Void
	{
		android('<project><architecture name="armv7" /><architecture name="arm64" /></project>', "update");
		Assert.isFalse(warned(ARMEABI));
	}

	public function testDisplayAndCleanDoNotWarnAboutArmv5():Void
	{
		for (command in ["display", "clean"])
		{
			forget(ARMEABI);
			android('<project><architecture name="armv5" /></project>', command);
			Assert.isFalse(warned(ARMEABI), command);
		}
	}

	public function testYUIIsWarnedAboutBeforeItRuns():Void
	{
		minify(["minify" => "", "yui" => ""]);
		Assert.isTrue(warned(YUI));
	}

	public function testMinifyingWithoutYUIIsNotWarnedAbout():Void
	{
		minify(["minify" => ""]);
		Assert.isFalse(warned(YUI));
	}

	/** Makes the Android target for a project, as a command would, with the SDK a folder of the fixture's **/
	private function android(xml:String, command:String):Void
	{
		fixture.target = ANDROID;
		fixture.command = command;
		var project:HXProject = fixture.parse(xml);

		// The Android target only checks that these folders exist
		FileSystem.createDirectory(Path.combine(fixture.directory, "android-sdk/build-tools/35.0.0"));
		FileSystem.createDirectory(Path.combine(fixture.directory, "android-ndk"));
		project.environment.set("ANDROID_SETUP", "true");
		project.environment.set("ANDROID_SDK", Path.combine(fixture.directory, "android-sdk"));
		project.environment.set("ANDROID_NDK_ROOT", Path.combine(fixture.directory, "android-ndk"));

		unmuted(function() new AndroidPlatform(command, project, fixture.targetFlags));
	}

	/** Minifies a script as an HTML5 build does with `flags`; nothing is run, so the minified file isn't there to copy back **/
	private function minify(flags:Map<String, String>):Void
	{
		fixture.target = HTML5;
		var project:HXProject = fixture.parse("<project />");
		for (flag in flags.keys())
		{
			project.targetFlags.set(flag, flags.get(flag));
		}

		var script = fixture.write("bin/Main.js", "console.log ('a script');");

		unmuted(function()
		{
			try
			{
				HTML5Helper.minify(project, script);
			}
			catch (e:Dynamic) {}
		});
	}

	/** Runs `work` with the log printing, as warnings are only kept while it does, and no command run **/
	private function unmuted(work:Void->Void):Void
	{
		var cwd = Sys.getCwd();
		var dryRun = System.dryRun;
		var mute = Log.mute;

		Sys.setCwd(fixture.directory);
		System.dryRun = true;
		Log.mute = false;
		Haxelib.pathOverrides.set("lime", LimeRepo.path());

		try
		{
			work();
		}
		catch (e:Dynamic)
		{
			Assert.fail("threw " + e);
		}

		Sys.setCwd(cwd);
		System.dryRun = dryRun;
		Log.mute = mute;
	}

	private static function warned(message:String):Bool
	{
		return @:privateAccess Log.sentWarnings.exists(key(message));
	}

	private static function forget(message:String):Void
	{
		@:privateAccess Log.sentWarnings.remove(key(message));
	}

	private static function key(message:String):String
	{
		return "\x1b[33;1mWarning:\x1b[0m \x1b[1m" + message + "\x1b[0m";
	}
}
