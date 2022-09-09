package lime.tools;

import hxp.*;
import lime.tools.Architecture;
import lime.tools.HXProject;
import sys.io.File;
import sys.FileSystem;

using StringTools;

class CSHelper
{
	public static var ndllSourceFiles:Array<String> = [
		"cs.ndll.NDLLFunction", "cs.ndll.CFFICSLoader", "cs.ndll.CSAbstract", "cs.ndll.CSHandleContainer", "cs.ndll.CSHandleScope", "cs.ndll.CSPersistent",
		"cs.ndll.DelegateConverter", "cs.ndll.HandleUtils", "cs.ndll.NativeMethods", "cs.ndll.NDLLFunction",
	];

	private static function getAndroidABIName(arch:Architecture):String
	{
		var name = switch (arch)
		{
			case ARMV5:
				"armeabi";
			case ARMV7:
				"armeabi-v7a";
			case ARM64:
				"arm64-v8a";
			case X86:
				"x86";
			case X64:
				"x86_64";
			case _:
				null;
		}

		if (name == null)
		{
			throw "Unsupported architecture:" + arch;
		}

		return name;
	}

	public static function getAndroidABINames(architectures:Array<Architecture>):String
	{
		var result = "";
		var first = true;

		for (arch in architectures)
		{
			if (first)
			{
				first = false;
			}
			else
			{
				result += ",";
			}

			var archName = getAndroidABIName(arch);
			result += archName;
		}

		return result;
	}

	public static function getAndroidNativeLibraryPaths(libPath:String, libraries:Array<NDLL>, architectures:Array<Architecture>):Array<String>
	{
		var paths = [];

		for (arch in architectures)
		{
			var archName = getAndroidABIName(arch);

			for (lib in libraries)
			{
				paths.push(FileSystem.absolutePath(libPath + "/" + archName + "/" + "lib" + lib.name + ".so").replace("/", "\\"));
			}
		}

		return paths;
	}

	public static function copySourceFiles(templatePaths:Array<String>, targetPath:String)
	{
		System.recursiveCopyTemplate(templatePaths, "cs/src", targetPath);
	}

	public static function addSourceFiles(txtPath:String, sourceFiles:Array<String>)
	{
		if (sourceFiles.length == 0)
		{
			return;
		}

		var file = File.append(txtPath, false);
		file.writeString('\nbegin modules\n');

		for (fileName in sourceFiles)
		{
			file.writeString('M $fileName\nC $fileName\n');
		}

		file.writeString('end modules\n');
		file.close();
	}

	public static function addAndroidResources(txtPath:String, resources:Array<String>)
	{
		if (resources.length == 0)
		{
			return;
		}

		var file = File.append(txtPath, false);
		file.writeString('\nbegin android_resources\n');

		for (resource in resources)
		{
			file.writeString('$resource\n');
		}

		file.writeString('end android_resources\n');
		file.close();
	}

	public static function addAssemblies(txtPath:String, assemblies:Array<String>)
	{
		if (assemblies.length == 0)
		{
			return;
		}

		var file = File.append(txtPath, false);
		file.writeString('\nbegin libs\n');

		for (assembly in assemblies)
		{
			file.writeString(assembly.replace("/", "\\") + '\n');
		}

		file.writeString('end libs\n');
		file.close();
	}

	public static function addNativeLibraries(txtPath:String, libPath:String, libraries:Array<NDLL>, architectures:Array<Architecture>)
	{
		if (libraries.length == 0)
		{
			return;
		}

		var file = File.append(txtPath, false);
		file.writeString('\nbegin native_libs\n');

		for (arch in architectures)
		{
			var archName = getAndroidABIName(arch);

			for (lib in libraries)
			{
				file.writeString(FileSystem.absolutePath(libPath + "/" + archName + "/" + "lib" + lib.name + ".so").replace("/", "\\") + '\n');
			}
		}

		file.writeString('end native_libs\n');
		file.close();
	}

	public static function addAndroidABIs(txtPath:String, architectures:Array<Architecture>)
	{
		if (architectures.length == 0)
		{
			return;
		}

		var file = File.append(txtPath, false);
		file.writeString('\nbegin android_abis\n');

		for (arch in architectures)
		{
			var archName = getAndroidABIName(arch);
			file.writeString(archName + '\n');
		}

		file.writeString('end android_abis\n');
		file.close();
	}

	public static function addAssets(txtPath:String, assets:Array<String>)
	{
		if (assets.length == 0)
		{
			return;
		}

		var file = File.append(txtPath, false);
		file.writeString('\nbegin android_assets\n');

		for (asset in assets)
		{
			file.writeString(FileSystem.absolutePath(asset).replace("/", "\\") + '\n');
		}

		file.writeString('end android_assets\n');
		file.close();
	}

	public static function addGUID(txtPath:String, guid:String)
	{
		var file = File.append(txtPath, false);
		file.writeString('\nbegin guid\n');

		file.writeString('$guid\n');

		file.writeString('end guid\n');
		file.close();
	}

	public static function compile(project:HXProject, path:String, outPath:String, arch:String, platform:String, buildFile:String = "hxcs_build.txt",
			noCompile:Bool = false)
	{
		var args = [
			"run",
			project.config.getString("cs.buildLibrary", "hxcs"),
			buildFile,
			"--arch",
			arch,
			"--platform",
			platform,
			"--out",
			outPath,
			"--unsafe"
		];
		if (noCompile) args.push("--no-compile");
		var code = Haxelib.runCommand(path, args);

		if (code != 0)
		{
			Sys.exit(code);
		}
	}

	public static function buildGradleProj(path:String)
	{
		var gradlePath = FileSystem.absolutePath(path + "/" + "gradlew");
		System.runCommand(path, gradlePath, ["build", "assembleRelease"]);
	}

	inline public static function buildSln(path:String, slnPath:String, task:String = null)
	{
		buildCSProj(path, slnPath, task);
	}

	public static function buildCSProj(path:String, csprojPath:String, task:String = null)
	{
		var msBuildPath = "C:/Program Files (x86)/MSBuild/14.0/Bin/MSBuild.exe";
		var absCSProjPath = FileSystem.absolutePath(csprojPath);
		var args = [absCSProjPath, "/p:Configuration=Release"];

		if (task != null)
		{
			args.push("/t:" + task);
		}

		System.runCommand(path, msBuildPath, args);
	}
}
