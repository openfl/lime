package lime.tools;

import hxp.*;
import lime.tools.HXProject;
import lime.tools.Platform;
import sys.io.File;
import sys.FileSystem;

class CPPHelper
{
	private static var rebuiltLibraries = new Map<String, Bool>();
	private static var rebuiltPaths = new Map<String, Bool>();

	public static function compile(project:HXProject, path:String, flags:Array<String> = null, buildFile:String = "Build.xml"):Void
	{
		project.normalizeNativeBackendDefines(getNativeTarget(flags));

		if (project.config.getBool("cpp.requireBuild", true))
		{
			var args = ["run", project.config.getString("cpp.buildLibrary", "hxcpp"), buildFile];
			var foundOptions = false;

			try
			{
				var options = Path.combine(path, "Options.txt");

				if (FileSystem.exists(options))
				{
					args.push("-options");
					args.push(Path.tryFullPath(options));

					// var list;
					// var input = File.read (options, false);
					// var text = input.readLine ();

					// if (StringTools.startsWith (text, " -D")) {

					// 	list = text.split (" ");

					// } else {

					// 	list = [ "-D" + StringTools.trim (text) ];

					// 	while (!input.eof ()) {

					// 		list.push ("-D" + StringTools.trim (input.readLine ()));

					// 	}

					// 	list.pop ();

					// }

					// for (option in list) {

					// 	if (option != "" && !StringTools.startsWith (option, "-Dno_compilation") && !StringTools.startsWith (option, "-Dno-compilation")) {

					// 		args.push (option);

					// 	}

					// }

					foundOptions = true;
				}
			}
			catch (e:Dynamic) {}

			if (flags != null)
			{
				args = args.concat(flags);
			}

			if (!foundOptions)
			{
				var skipSDLSound = shouldSkipSDLSoundDefine(project, flags);

				for (key in project.haxedefs.keys())
				{
					if (skipSDLSound && key == "lime_sdl_sound") continue;

					var value = project.haxedefs.get(key);

					if (value == null || value == "")
					{
						args.push("-D" + key);
					}
					else
					{
						args.push("-D" + key + "=" + value);
					}
				}
			}

			if (project.debug)
			{
				args.push("-debug");
			}

			if (Log.verbose)
			{
				args.push("-verbose");
			}

			if (!Log.enableColor)
			{
				// args.push ("-nocolor");
				Sys.putEnv("HXCPP_NO_COLOR", "");
			}

			if (System.hostPlatform == WINDOWS && !project.environment.exists("HXCPP_COMPILE_THREADS"))
			{
				var threads = 1;

				if (System.processorCores > 1)
				{
					threads = System.processorCores - 1;
				}

				Sys.putEnv("HXCPP_COMPILE_THREADS", Std.string(threads));
			}

			Sys.putEnv("HXCPP_EXIT_ON_ERROR", "");

			var code = Haxelib.runCommand(path, args);

			if (code != 0)
			{
				Sys.exit(code);
			}
		}
	}

	public static function rebuild(project:HXProject, commands:Array<Array<String>>, path:String = null, buildFile:String = null):Void
	{
		var buildRelease = (!project.targetFlags.exists("debug"));
		var buildDebug = (project.targetFlags.exists("debug")
			|| (!project.targetFlags.exists("rebuild")
				&& !project.targetFlags.exists("release")
				&& !project.targetFlags.exists("final")
				&& project.config.exists("project.rebuild.fulldebug")));

		for (haxelib in project.haxelibs)
		{
			if (!rebuiltLibraries.exists(haxelib.name))
			{
				var defines = MapTools.copy(project.defines);
				defines.set("rebuild", "1");

				var haxelibProject = HXProject.fromHaxelib(haxelib, defines);

				if (haxelibProject == null)
				{
					haxelibProject = new HXProject();
					haxelibProject.config.set("project.rebuild.path", Path.combine(Haxelib.getPath(haxelib), "project"));
				}

				MapTools.copyKeys(project.targetFlags, haxelibProject.targetFlags);

				rebuiltLibraries.set(haxelib.name, true);

				if (!rebuiltPaths.exists(haxelibProject.config.get("project.rebuild.path")))
				{
					rebuiltPaths.set(haxelibProject.config.get("project.rebuild.path"), true);
					rebuild(haxelibProject, commands);
				}
			}
		}

		if (project.targetFlags.exists("clean"))
		{
			if (buildRelease)
			{
				for (command in commands)
				{
					rebuildSingle(project, command.concat(["clean"]), path, buildFile);
				}
			}

			if (buildDebug)
			{
				for (command in commands)
				{
					rebuildSingle(project, command.concat(["-Ddebug", "-Dfulldebug", "clean"]), path, buildFile);
				}
			}
		}

		for (command in commands)
		{
			if (buildRelease)
			{
				rebuildSingle(project, command, path, buildFile);
			}

			if (buildDebug)
			{
				rebuildSingle(project, command.concat(["-Ddebug", "-Dfulldebug"]), path, buildFile);
			}
		}
	}

	public static function rebuildSingle(project:HXProject, flags:Array<String> = null, path:String = null, buildFile:String = null):Void
	{
		project.normalizeNativeBackendDefines(getNativeTarget(flags));

		if (path == null)
		{
			path = project.config.get("project.rebuild.path");
		}

		if (path == null)
		{
			return;
		}

		if (!FileSystem.exists(path))
		{
			Log.warn("Skipping rebuild. Path not found: "
				+ path
				+
				"\nIf you are using a release from Haxelib, source code for native binaries may not be bundled. To rebuild, you may need to check out the full repository.");
			return;
		}

		if (buildFile == null && project.config.exists("project.rebuild.file"))
		{
			buildFile = project.config.get("project.rebuild.file");
		}

		if (buildFile == null) buildFile = "Build.xml";

		if (!FileSystem.exists(Path.combine(path, buildFile)))
		{
			Log.warn("Skipping rebuild. Path not found: "
				+ path
				+
				"\nIf you are using a release from Haxelib, source code for native binaries may not be bundled. To rebuild, you may need to check out the full repository.");
			return;
		}

		var args = ["run", project.config.getString("cpp.buildLibrary", "hxcpp"), buildFile];

		if (flags != null)
		{
			args = args.concat(flags);
		}

		var skipSDLSound = shouldSkipSDLSoundDefine(project, flags);

		for (key in project.haxedefs.keys())
		{
			if (skipSDLSound && key == "lime_sdl_sound") continue;

			var value = project.haxedefs.get(key);

			if (value == null || value == "")
			{
				args.push("-D" + key);
			}
			else
			{
				args.push("-D" + key + "=" + value);
			}
		}

		/*if (project.debug) {

			args.push ("-Ddebug");

		}*/

		if (project.targetFlags.exists("static"))
		{
			args.push("-Dstatic_link");
		}

		if (Log.verbose)
		{
			args.push("-verbose");
		}

		if (!Log.enableColor)
		{
			// args.push ("-nocolor");
			Sys.putEnv("HXCPP_NO_COLOR", "");
		}

		if (System.hostPlatform == WINDOWS && !project.environment.exists("HXCPP_COMPILE_THREADS"))
		{
			var threads = 1;

			if (System.processorCores > 1)
			{
				threads = System.processorCores - 1;
			}

			Sys.putEnv("HXCPP_COMPILE_THREADS", Std.string(threads));
		}

		Sys.putEnv("HXCPP_EXIT_ON_ERROR", "");

		Haxelib.runCommand(path, args);
	}

	private static function getNativeTarget(flags:Array<String>):Platform
	{
		if (flags != null)
		{
			for (i in 0...flags.length)
			{
				switch (getDefineFromFlag(flags, i))
				{
					case "windows":
						return Platform.WINDOWS;
					case "mac":
						return Platform.MAC;
					case "linux":
						return Platform.LINUX;
				}
			}
		}

		return null;
	}

	private static function getDefineFromFlag(flags:Array<String>, index:Int):String
	{
		var flag = flags[index];

		if (flag == "-D")
		{
			return index + 1 < flags.length ? flags[index + 1] : null;
		}

		if (StringTools.startsWith(flag, "-D"))
		{
			return flag.substr(2);
		}

		return null;
	}

	private static function hasDefine(project:HXProject, flags:Array<String>, name:String):Bool
	{
		if (project.haxedefs.exists(name)) return true;

		if (flags != null)
		{
			for (i in 0...flags.length)
			{
				if (getDefineFromFlag(flags, i) == name) return true;
			}
		}

		return false;
	}

	private static function shouldSkipSDLSoundDefine(project:HXProject, flags:Array<String>):Bool
	{
		var nativeTarget = getNativeTarget(flags);
		if (nativeTarget == null)
		{
			nativeTarget = project.target;
		}

		return (nativeTarget == Platform.WINDOWS || nativeTarget == Platform.MAC || nativeTarget == Platform.LINUX)
			&& !hasDefine(project, flags, "lime-sdl2")
			&& !hasDefine(project, flags, "LIME_SDL2");
	}
}
