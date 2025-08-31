package lime.tools;

import hxp.Haxelib;
import hxp.Log;
import sys.FileSystem;
import lime.tools.ConfigHelper;
import lime.tools.HXProject;
import lime.tools.Platform;
import hxp.Path;
import hxp.System;

class HashlinkHelper
{
	public static inline var BUNDLED_HL_VER = "1.14.0";

	public static function copyHashlink(project:HXProject, targetDirectory:String, applicationDirectory:String, executablePath:String, ?is64 = true)
	{
		var platform = project.target;
		var bindir = switch project.target
		{
			case LINUX: "Linux";
			case MAC: "Mac";
			case WINDOWS: "Windows";
			default:
				Log.error('HashLink is not supported on ${project.target} (Supported: Windows, Mac and Linux)');
				Sys.exit(1);
				"";
		};
		if(is64) {
			bindir += "64";
		}

		var hlPath = ConfigHelper.getConfigValue("HL_PATH");
		if (hlPath == null)
		{
			System.recursiveCopyTemplate(project.templatePaths, 'bin/hl/$bindir', applicationDirectory);
			System.renameFile(Path.combine(applicationDirectory, "hl" + (project.target == WINDOWS ? ".exe" : "")), executablePath);

			if (project.targetFlags.exists("hlc"))
			{
				var limeDirectory = Haxelib.getPath(new Haxelib("lime"), true);
				var includeDirectory = sys.FileSystem.exists(Path.combine(limeDirectory, "project"))
					? Path.combine(limeDirectory, "project/lib/hashlink/src")
					: Path.combine(limeDirectory,  "templates/bin/hl/include");

				System.copyFile(Path.combine(includeDirectory, "hlc.h"), Path.combine(targetDirectory, "obj/hlc.h"), null, false);
				System.copyFile(Path.combine(includeDirectory, "hl.h"), Path.combine(targetDirectory, "obj/hl.h"), null, false);
				System.copyFile(Path.combine(includeDirectory, "hlc_main.c"), Path.combine(targetDirectory, "obj/hlc_main.c"), null, false);
			}
		}
		else
		{
			if (!project.targetFlags.exists("hlc"))
			{
				System.copyFile(Path.combine(hlPath, "hl" + (platform == WINDOWS ? ".exe" : "")), executablePath);
			}
			if (platform == WINDOWS)
			{
				System.copyFile(Path.combine(hlPath, "libhl.dll"), Path.combine(applicationDirectory, "libhl.dll"));
				var msvcrPath = Path.combine(hlPath, "msvcr120.dll");
				if (FileSystem.exists(msvcrPath))
				{
					System.copyFile(msvcrPath, Path.combine(applicationDirectory, "msvcr120.dll"));
				}
				var vcruntimePath = Path.combine(hlPath, "vcruntime140.dll");
				if (FileSystem.exists(vcruntimePath))
				{
					System.copyFile(vcruntimePath, Path.combine(applicationDirectory, "vcruntime140.dll"));
				}
			}
			else if (platform == MAC || platform == IOS)
			{
				System.copyFile(Path.combine(hlPath, "libhl.dylib"), Path.combine(applicationDirectory, "libhl.dylib"));
			}
			else
			{
				System.copyFile(Path.combine(hlPath, "libhl.so"), Path.combine(applicationDirectory, "libhl.so"));
			}

			for (file in System.readDirectory(hlPath)
				.filter(function(f) return Path.extension(f) == "hdll"
					&& Path.withoutDirectory(f) != "sdl.hdll"
					&& Path.withoutDirectory(f) != "openal.hdll"))
			{
				System.copyFile(file, Path.combine(applicationDirectory, Path.withoutDirectory(file)));
			}

			if (project.targetFlags.exists("hlc"))
			{
				for (file in System.readDirectory(Path.combine(hlPath, "include")))
				{
					System.copyFile(file, Path.combine(targetDirectory, Path.combine("obj", Path.withoutDirectory(file))));
				}
			}
		}

		// make sure no hxcpp hash files or MSVC build artifacts remain

		for (file in System.readDirectory(applicationDirectory))
		{
			switch Path.extension(file)
			{
				case "hash", "pdb", "ilk", "exp":
					System.deleteFile(file);
				case "lib":
					if (platform != WINDOWS)
					{
						System.deleteFile(file);
					}
				default:
			}
		}
		if (project.targetFlags.exists("hlc"))
		{
			if (sys.FileSystem.exists(executablePath))
			{
				System.deleteFile(executablePath);
			}

			var appMainCPath = Path.combine(targetDirectory, "obj/ApplicationMain.c");
			var appMainCText = System.readText(appMainCPath);
			var index = appMainCText.indexOf("#ifndef HL_MAKE");
			appMainCText = appMainCText.substr(0, index) + "
// --------- START LIME HL/C INJECTED CODE --------- //
// undefine things to avoid Haxe field name conflicts
#undef BIG_ENDIAN
#undef LITTLE_ENDIAN
#undef TRUE
#undef FALSE
#undef BOOLEAN
#undef ERROR
#undef NO_ERROR
#undef DELETE
#undef OPTIONS
#undef IN
#undef OUT
#undef ALTERNATE
#undef OPTIONAL
#undef DOUBLE_CLICK
#undef DIFFERENCE
#undef POINT
#undef RECT
#undef OVERFLOW
#undef UNDERFLOW
#undef DOMAIN
#undef TRANSPARENT
#undef CONST
#undef CopyFile
#undef COLOR_HIGHLIGHT
#undef __valid
#undef WAIT_FAILED
// ---------- END LIME HL/C INJECTED CODE ---------- //
" + appMainCText.substr(index);
			System.writeText(appMainCText, appMainCPath);
		}
		else
		{
			System.copyFile(Path.combine(targetDirectory, "obj/ApplicationMain.hl"), Path.combine(applicationDirectory, "hlboot.dat"));
		}
	}
}
