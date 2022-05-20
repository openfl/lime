package lime.tools;

import hxp.Log;
import sys.FileSystem;
import lime.tools.ConfigHelper;
import lime.tools.HXProject;
import lime.tools.Platform;
import hxp.Path;
import hxp.System;

class HashlinkHelper
{
	public static function copyHashlink(project:HXProject, targetDirectory:String, applicationDirectory:String, executablePath:String, ?is64 = true)
	{
		var platform = project.target;
		var bindir = switch project.target
		{
			case LINUX: "Linux";
			case MAC: "Mac";
			case WINDOWS: "Windows";
			default:
				Log.error('Hashlink is not supported on ${project.target} (Supported: Windows, Mac and Linux)');
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
		}
		else
		{
			System.copyFile(Path.combine(hlPath, "hl" + (platform == WINDOWS ? ".exe" : "")), executablePath);
			if (platform == WINDOWS)
			{
				System.copyFile(Path.combine(hlPath, "libhl.dll"), Path.combine(applicationDirectory, "libhl.dll"));
				var msvcrPath = Path.combine(hlPath, "msvcr120.dll");
				if (FileSystem.exists(msvcrPath))
				{
					System.copyFile(msvcrPath, Path.combine(applicationDirectory, "msvcr120.dll"));
				}
				var vcruntimePath = Path.combine(hlPath, "vcruntime.dll.dll");
				if (FileSystem.exists(vcruntimePath))
				{
					System.copyFile(vcruntimePath, Path.combine(applicationDirectory, "vcruntime.dll"));
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
		}

		// make sure no hxcpp hash files or MSVC build artifacts remain

		for (file in System.readDirectory(applicationDirectory))
		{
			switch Path.extension(file)
			{
				case "hash", "lib", "pdb", "ilk", "exp":
					System.deleteFile(file);
				default:
			}
		}
		System.copyFile(targetDirectory + "/obj/ApplicationMain.hl", Path.combine(applicationDirectory, "hlboot.dat"));
	}
}
