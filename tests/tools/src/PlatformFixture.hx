import hxp.Haxelib;
import hxp.Log;
import hxp.Path;
import hxp.System;
import lime.tools.HXProject;
import lime.tools.PlatformTarget;
import lime.utils.AssetManifest;
import sys.FileSystem;
import sys.io.File;

/**
	Runs a target's update step on a `Fixture` project, as `lime update <target>` does once it
	has read the project file, and reads the files that it wrote. Commands the tools would
	run are skipped, as `-dryrun` skips them, so no SDK is needed.
**/
class PlatformFixture
{
	public var fixture(default, null):Fixture;
	public var platform(default, null):PlatformTarget;

	/**
		The project the platform works on: the parsed one over the target's defaults.
	**/
	public var project(get, never):HXProject;

	public function new(fixture:Fixture)
	{
		this.fixture = fixture;
		fixture.command = "update";
	}

	/**
		Lime's own templates, which a project gets from Lime's include.xml.
	**/
	public static function templates():String
	{
		return Path.combine(LimeRepo.path(), "templates");
	}

	public function exists(file:String):Bool
	{
		return FileSystem.exists(path(file));
	}

	/**
		The full path of a file in the target's output folder, such as "bin/index.html".
	**/
	public function path(file:String):String
	{
		return Path.combine(fixture.directory, Path.combine(platform.targetDirectory, file));
	}

	public function read(file:String):String
	{
		return File.getContent(path(file));
	}

	/**
		Parses a project file, then runs the update step of the fixture's target on it.
		`configure` can change the parsed project first, as the command line does, and
		`prepare` is given the platform before its update runs.
	**/
	public function update(xml:String, configure:HXProject->Void = null, prepare:PlatformTarget->Void = null):Void
	{
		var parsed:HXProject = fixture.parse(xml);
		parsed.templatePaths.unshift(templates());

		// Without a build number the tools count builds in a ".build" file, starting at 1
		if (parsed.meta.buildNumber == null) parsed.meta.buildNumber = "1";

		if (fixture.target == ANDROID)
		{
			// The Android target only checks that these folders exist
			FileSystem.createDirectory(Path.combine(fixture.directory, "android-sdk/build-tools/35.0.0"));
			FileSystem.createDirectory(Path.combine(fixture.directory, "android-ndk"));

			parsed.environment.set("ANDROID_SETUP", "true");
			parsed.environment.set("ANDROID_SDK", Path.combine(fixture.directory, "android-sdk"));
			parsed.environment.set("ANDROID_NDK_ROOT", Path.combine(fixture.directory, "android-ndk"));
		}

		if (fixture.target == IOS)
		{
			// Otherwise the iOS target asks Xcode for its SDK version
			parsed.environment.set("IPHONE_VER", "17.0");
		}

		if (configure != null) configure(parsed);

		if (fixture.target == IOS)
		{
			// The iOS target reads the TLS build file of the hxcpp an application is built with.
			// Unless a test gives that hxcpp, one without the file stands in, so the haxelib
			// command doesn't run and the output doesn't depend on the hxcpp installed.
			var buildLibrary = parsed.config.getString("cpp.buildLibrary", "hxcpp");
			if (!Haxelib.pathOverrides.exists(buildLibrary)) fixture.addHaxelib(buildLibrary, "<project />");
		}

		var cwd = Sys.getCwd();
		var dryRun = System.dryRun;
		var mute = Log.mute;

		Sys.setCwd(fixture.directory);
		System.dryRun = true;
		Log.mute = true;
		Haxelib.pathOverrides.set("lime", LimeRepo.path());

		try
		{
			platform = create(parsed);
			if (prepare != null) prepare(platform);
			platform.execute([]);
		}
		catch (e:Dynamic)
		{
			Sys.setCwd(cwd);
			System.dryRun = dryRun;
			Log.mute = mute;
			throw e;
		}

		Sys.setCwd(cwd);
		System.dryRun = dryRun;
		Log.mute = mute;
	}

	/**
		The value of the double-quoted Haxe string that follows `prefix` in generated code and
		is followed by `suffix` at the end of its line, or null if what is written there is
		not one string, as when a quote in it was not escaped.
	**/
	public static function haxeString(source:String, prefix:String, suffix:String):String
	{
		var start = source.indexOf(prefix + "\"");
		if (start == -1) return null;

		start += prefix.length + 1;

		var end = source.indexOf("\n", start);
		if (end == -1) end = source.length;

		var line = source.substring(start, end);
		if (StringTools.endsWith(line, "\r")) line = line.substr(0, line.length - 1);
		if (!StringTools.endsWith(line, "\"" + suffix)) return null;

		var body = line.substr(0, line.length - suffix.length - 1);
		var value = new StringBuf();
		var i = 0;

		while (i < body.length)
		{
			var char = body.charAt(i++);

			if (char == "\"") return null;

			if (char == "\\")
			{
				if (i >= body.length) return null;

				switch (body.charAt(i++))
				{
					case "n": value.add("\n");
					case "r": value.add("\r");
					case "t": value.add("\t");
					case "\"": value.add("\"");
					case "'": value.add("'");
					case "\\": value.add("\\");
					default: return null;
				}
			}
			else
			{
				value.add(char);
			}
		}

		return value.toString();
	}

	/**
		Parses a generated file as XML the way a strict reader does, so an unescaped "&" or
		"<" in a value is an error here as it is for the Android, Xcode and AIR tools.
	**/
	public static function xml(text:String):Xml
	{
		return haxe.xml.Parser.parse(text, true);
	}

	/**
		The asset manifest that generated code registers for a library, read from
		ManifestResources.hx with Lime's own `AssetManifest.parse()`.
	**/
	public static function embeddedManifest(manifestResources:String, library:String = "default"):AssetManifest
	{
		var register = manifestResources.indexOf("Assets.registerLibrary (\"" + library + "\"");
		if (register == -1) return null;

		var start = manifestResources.lastIndexOf("data = '", register);
		if (start == -1) return null;

		start += "data = '".length;

		var end = manifestResources.indexOf("';", start);
		if (end == -1) return null;

		return AssetManifest.parse(manifestResources.substring(start, end));
	}

	/**
		The window attributes that generated ApplicationMain.hx code creates each window
		with, as the text written for each one.
	**/
	public static function windowAttributes(applicationMain:String):Array<Map<String, String>>
	{
		var windows = [];
		var blocks = applicationMain.split("var attributes:lime.ui.WindowAttributes =");
		blocks.shift();

		for (block in blocks)
		{
			var end = block.indexOf("if (app.window == null)");
			if (end > -1) block = block.substr(0, end);

			var attributes = new Map<String, String>();
			var entry = ~/^\s*(#if !web )?([A-Za-z]+): (.*?),?( #end,?)?\s*$/;

			for (line in block.split("\n"))
			{
				if (entry.match(line))
				{
					attributes.set(entry.matched(2), entry.matched(3));
				}
			}

			windows.push(attributes);
		}

		return windows;
	}

	private function create(parsed:HXProject):PlatformTarget
	{
		return switch (fixture.target)
		{
			case ANDROID: new AndroidPlatform("update", parsed, fixture.targetFlags);
			case HTML5: new HTML5Platform("update", parsed, fixture.targetFlags);
			case IOS: new IOSPlatform("update", parsed, fixture.targetFlags);
			case LINUX: new LinuxPlatform("update", parsed, fixture.targetFlags);
			case MAC: new MacPlatform("update", parsed, fixture.targetFlags);
			case WINDOWS: new WindowsPlatform("update", parsed, fixture.targetFlags);
			default: throw "No platform fixture for " + Std.string(fixture.target);
		}
	}

	private function get_project():HXProject
	{
		return platform.project;
	}
}
