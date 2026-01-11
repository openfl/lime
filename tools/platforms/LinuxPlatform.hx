package;

import lime.tools.HashlinkHelper;
import hxp.Haxelib;
import hxp.HXML;
import hxp.Path;
import hxp.Log;
import hxp.NDLL;
import hxp.System;
import lime.tools.Architecture;
import lime.tools.AssetHelper;
import lime.tools.AssetType;
import lime.tools.CPPHelper;
import lime.tools.DeploymentHelper;
import lime.tools.HXProject;
import lime.tools.JavaHelper;
import lime.tools.NekoHelper;
import lime.tools.NodeJSHelper;
import lime.tools.Orientation;
import lime.tools.Platform;
import lime.tools.PlatformTarget;
import lime.tools.ProjectHelper;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class LinuxPlatform extends PlatformTarget
{
	private var applicationDirectory:String;
	private var executablePath:String;
	private var is64:Bool;
	private var isRaspberryPi:Bool;
	private var targetType:String;

	public function new(command:String, _project:HXProject, targetFlags:Map<String, String>)
	{
		super(command, _project, targetFlags);

		var defaults = new HXProject();

		defaults.meta =
			{
				title: "MyApplication",
				description: "",
				packageName: "com.example.myapp",
				version: "1.0.0",
				company: "",
				companyUrl: "",
				buildNumber: null,
				companyId: ""
			};

		defaults.app =
			{
				main: "Main",
				file: "MyApplication",
				path: "bin",
				preloader: "",
				swfVersion: 17,
				url: "",
				init: null
			};

		defaults.window =
			{
				width: 800,
				height: 600,
				parameters: "{}",
				background: 0xFFFFFF,
				fps: 30,
				hardware: true,
				display: 0,
				resizable: true,
				borderless: false,
				orientation: Orientation.AUTO,
				vsync: false,
				fullscreen: false,
				allowHighDPI: true,
				alwaysOnTop: false,
				antialiasing: 0,
				allowShaders: true,
				requireShaders: false,
				depthBuffer: true,
				stencilBuffer: true,
				colorDepth: 32,
				maximized: false,
				minimized: false,
				hidden: false,
				title: ""
			};

		switch (System.hostArchitecture)
		{
			case ARMV6:
				defaults.architectures = [ARMV6];
			case ARMV7:
				defaults.architectures = [ARMV7];
			case ARM64:
				defaults.architectures = [ARM64];
			case X86:
				defaults.architectures = [X86];
			case X64:
				defaults.architectures = [X64];
			default:
				defaults.architectures = [];
		}

		defaults.window.allowHighDPI = false;

		for (i in 1...project.windows.length)
		{
			defaults.windows.push(defaults.window);
		}

		defaults.merge(project);
		project = defaults;

		for (excludeArchitecture in project.excludeArchitectures)
		{
			project.architectures.remove(excludeArchitecture);
		}

		for (architecture in project.architectures)
		{
			if (!targetFlags.exists("32") && !targetFlags.exists("x86_32") && (architecture == Architecture.X64 || architecture == Architecture.ARM64))
			{
				is64 = true;
			}
			else if (architecture == Architecture.ARMV7)
			{
				is64 = false;
			}
		}

		if (project.targetFlags.exists("neko"))
		{
			targetType = "neko";
		}
		else if (project.targetFlags.exists("hl") || targetFlags.exists("hlc"))
		{
			targetType = "hl";
			is64 = true;
			var hlVer = project.haxedefs.get("hl-ver");
			if (hlVer == null)
			{
				var hlPath = project.defines.get("HL_PATH");
				if (hlPath == null)
				{
					// Haxe's default target version for HashLink may be
					// different (newer even) than the build of HashLink that
					// is bundled with Lime. if using Lime's bundled HashLink,
					// set hl-ver to the correct version
					project.haxedefs.set("hl-ver", HashlinkHelper.BUNDLED_HL_VER);
				}
			}
		}
		else if (project.targetFlags.exists("nodejs"))
		{
			targetType = "nodejs";
		}
		else if (project.targetFlags.exists("java"))
		{
			targetType = "java";
		}
		else
		{
			targetType = "cpp";
		}

		var defaultTargetDirectory = switch (targetType)
		{
			case "cpp": "linux";
			case "hl": project.targetFlags.exists("hlc") ? "hlc" : targetType;
			default: targetType;
		}
		targetDirectory = Path.combine(project.app.path, project.config.getString("linux.output-directory", defaultTargetDirectory));
		targetDirectory = StringTools.replace(targetDirectory, "arch64", is64 ? "64" : "");
		applicationDirectory = targetDirectory + "/bin/";
		executablePath = Path.combine(applicationDirectory, project.app.file);
	}

	public override function build():Void
	{
		var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";

		System.mkdir(targetDirectory);

		if (!project.targetFlags.exists("static") || targetType != "cpp")
		{
			var targetSuffix = (targetType == "hl") ? ".hdll" : null;

			for (ndll in project.ndlls)
			{
				// TODO: Support single binary for HashLink
				if (targetType == "hl")
				{
					ProjectHelper.copyLibrary(project, ndll, "Linux" + (is64 ? "64" : ""), "", ".hdll", applicationDirectory, project.debug, targetSuffix);
				}
				else
				{
					ProjectHelper.copyLibrary(project, ndll, "Linux" + (( System.hostArchitecture == ARMV7 || System.hostArchitecture == ARM64)?"Arm":"") + (is64 ? "64" : ""), "",
						(ndll.haxelib != null
							&& (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dll" : ".ndll", applicationDirectory,
						project.debug, targetSuffix);
				}
			}
		}

		if (targetType == "neko")
		{
			System.runCommand("", "haxe", [hxml]);

			if (noOutput) return;

			NekoHelper.createExecutable(project.templatePaths, "linux" + (( System.hostArchitecture == ARMV7 || System.hostArchitecture == ARM64)?"Arm":"") + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
			NekoHelper.copyLibraries(project.templatePaths, "linux" + (is64 ? "64" : ""), applicationDirectory);

		}
		else if (targetType == "hl")
		{
			System.runCommand("", "haxe", [hxml]);

			if (noOutput) return;

			HashlinkHelper.copyHashlink(project, targetDirectory, applicationDirectory, executablePath, is64);

			if (project.targetFlags.exists("hlc"))
			{
				var compiler = project.targetFlags.exists("clang") ? "clang" : "gcc";
				var command = [compiler, "-O3", "-o", executablePath, "-std=c11", "-Wl,-rpath,$ORIGIN", "-I", Path.combine(targetDirectory, "obj"), Path.combine(targetDirectory, "obj/ApplicationMain.c"), "-L", applicationDirectory];
				for (file in System.readDirectory(applicationDirectory))
				{
					switch Path.extension(file)
					{
						case "so", "hdll":
							// ensure the executable knows about every library
							command.push("-l:" + Path.withoutDirectory(file));
						default:
					}
				}
				command.push("-lm");
				System.runCommand("", command.shift(), command);
			}
		}
		else if (targetType == "nodejs")
		{
			System.runCommand("", "haxe", [hxml]);
			// NekoHelper.createExecutable (project.templatePaths, "linux" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
			// NekoHelper.copyLibraries (project.templatePaths, "linux" + (is64 ? "64" : ""), applicationDirectory);
		}
		else if (targetType == "java")
		{
			var libPath = Path.combine(Haxelib.getPath(new Haxelib("lime")), "templates/java/lib/");

			System.runCommand("", "haxe", [hxml, "-java-lib", libPath + "disruptor.jar", "-java-lib", libPath + "lwjgl.jar"]);
			// System.runCommand ("", "haxe", [ hxml ]);

			if (noOutput) return;

			var haxeVersion = project.environment.get("haxe_ver");
			var haxeVersionString = "3404";

			if (haxeVersion.length > 4)
			{
				haxeVersionString = haxeVersion.charAt(0)
					+ haxeVersion.charAt(2)
					+ (haxeVersion.length == 5 ? "0" + haxeVersion.charAt(4) : haxeVersion.charAt(4) + haxeVersion.charAt(5));
			}

			System.runCommand(targetDirectory + "/obj", "haxelib", ["run", "hxjava", "hxjava_build.txt", "--haxe-version", haxeVersionString]);
			System.recursiveCopy(targetDirectory + "/obj/lib", Path.combine(applicationDirectory, "lib"));
			System.copyFile(targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-Debug" : "") + ".jar",
				Path.combine(applicationDirectory, project.app.file + ".jar"));
			JavaHelper.copyLibraries(project.templatePaths, "Linux" + (is64 ? "64" : ""), applicationDirectory);
		}
		else
		{
			var haxeArgs:Array<String> = [hxml];
			var flags:Array<String> = [];

			if (is64)
			{
				if (System.hostArchitecture == ARM64)
				{
					haxeArgs.push("-D");
					haxeArgs.push("HXCPP_ARM64");
					flags.push("-DHXCPP_ARM64");
				}
				else
				{
					haxeArgs.push("-D");
					haxeArgs.push("HXCPP_M64");
					flags.push("-DHXCPP_M64");
				}
			}
			else
			{
				haxeArgs.push("-D");
				haxeArgs.push("HXCPP_M32");
				flags.push("-DHXCPP_M32");
			}

			if (project.target != System.hostPlatform)
			{
				var hxcpp_xlinux64_cxx = project.defines.get("HXCPP_XLINUX64_CXX");
				if (hxcpp_xlinux64_cxx == null)
				{
					hxcpp_xlinux64_cxx = "x86_64-unknown-linux-gnu-g++";
				}
				var hxcpp_xlinux64_strip = project.defines.get("HXCPP_XLINUX64_STRIP");
				if (hxcpp_xlinux64_strip == null)
				{
					hxcpp_xlinux64_strip = "x86_64-unknown-linux-gnu-strip";
				}
				var hxcpp_xlinux64_ranlib = project.defines.get("HXCPP_XLINUX64_RANLIB");
				if (hxcpp_xlinux64_ranlib == null)
				{
					hxcpp_xlinux64_ranlib = "x86_64-unknown-linux-gnu-ranlib";
				}
				var hxcpp_xlinux64_ar = project.defines.get("HXCPP_XLINUX64_AR");
				if (hxcpp_xlinux64_ar == null)
				{
					hxcpp_xlinux64_ar = "x86_64-unknown-linux-gnu-ar";
				}
				flags.push('-DHXCPP_XLINUX64_CXX=$hxcpp_xlinux64_cxx');
				flags.push('-DHXCPP_XLINUX64_STRIP=$hxcpp_xlinux64_strip');
				flags.push('-DHXCPP_XLINUX64_RANLIB=$hxcpp_xlinux64_ranlib');
				flags.push('-DHXCPP_XLINUX64_AR=$hxcpp_xlinux64_ar');

				var hxcpp_xlinux32_cxx = project.defines.get("HXCPP_XLINUX32_CXX");
				if (hxcpp_xlinux32_cxx == null)
				{
					hxcpp_xlinux32_cxx = "i686-unknown-linux-gnu-g++";
				}
				var hxcpp_xlinux32_strip = project.defines.get("HXCPP_XLINUX32_STRIP");
				if (hxcpp_xlinux32_strip == null)
				{
					hxcpp_xlinux32_strip = "i686-unknown-linux-gnu-strip";
				}
				var hxcpp_xlinux32_ranlib = project.defines.get("HXCPP_XLINUX32_RANLIB");
				if (hxcpp_xlinux32_ranlib == null)
				{
					hxcpp_xlinux32_ranlib = "i686-unknown-linux-gnu-ranlib";
				}
				var hxcpp_xlinux32_ar = project.defines.get("HXCPP_XLINUX32AR");
				if (hxcpp_xlinux32_ar == null)
				{
					hxcpp_xlinux32_ar = "i686-unknown-linux-gnu-ar";
				}
				flags.push('-DHXCPP_XLINUX32_CXX=$hxcpp_xlinux32_cxx');
				flags.push('-DHXCPP_XLINUX32_STRIP=$hxcpp_xlinux32_strip');
				flags.push('-DHXCPP_XLINUX32_RANLIB=$hxcpp_xlinux32_ranlib');
				flags.push('-DHXCPP_XLINUX32_AR=$hxcpp_xlinux32_ar');
			}

			if (!project.targetFlags.exists("static"))
			{
				System.runCommand("", "haxe", haxeArgs);

				if (noOutput) return;

				CPPHelper.compile(project, targetDirectory + "/obj", flags);

				System.copyFile(targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), executablePath);
			}
			else
			{
				System.runCommand("", "haxe", haxeArgs.concat(["-D", "static_link"]));

				if (noOutput) return;

				CPPHelper.compile(project, targetDirectory + "/obj", flags.concat(["-Dstatic_link"]));
				CPPHelper.compile(project, targetDirectory + "/obj", flags, "BuildMain.xml");

				System.copyFile(targetDirectory + "/obj/Main" + (project.debug ? "-debug" : ""), executablePath);
			}
		}

		if (System.hostPlatform != WINDOWS && (targetType != "nodejs" && targetType != "java"))
		{
			System.runCommand("", "chmod", ["755", executablePath]);
		}
	}

	public override function clean():Void
	{
		if (FileSystem.exists(targetDirectory))
		{
			System.removeDirectory(targetDirectory);
		}
	}

	public override function deploy():Void
	{
		DeploymentHelper.deploy(project, targetFlags, targetDirectory, "Linux " + (is64 ? "64" : "32") + "-bit");
	}

	public override function display():Void
	{
		if (project.targetFlags.exists("output-file"))
		{
			Sys.println(executablePath);
		}
		else
		{
			Sys.println(getDisplayHXML().toString());
		}
	}

	private function generateContext():Dynamic
	{
		// var project = project.clone ();

		if(targetFlags.exists('rpi'))
		{
			project.haxedefs.set("rpi", 1);
		}

		var context = project.templateContext;

		context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
		context.NODE_FILE = targetDirectory + "/bin/ApplicationMain.js";
		context.HL_FILE = targetDirectory + "/obj/ApplicationMain" + (project.defines.exists("hlc") ? ".c" : ".hl");
		context.CPP_DIR = targetDirectory + "/obj/";
		context.BUILD_DIR = project.app.path + "/linux" + (is64 ? "64" : "") + (isRaspberryPi ? "-rpi" : "");
		context.WIN_ALLOW_SHADERS = false;

		return context;
	}

	private function getDisplayHXML():HXML
	{
		var path = targetDirectory + "/haxe/" + buildType + ".hxml";

		// try to use the existing .hxml file. however, if the project file was
		// modified more recently than the .hxml, then the .hxml cannot be
		// considered valid anymore. it may cause errors in editors like vscode.
		if (FileSystem.exists(path)
			&& (project.projectFilePath == null || !FileSystem.exists(project.projectFilePath)
				|| (FileSystem.stat(path).mtime.getTime() > FileSystem.stat(project.projectFilePath).mtime.getTime())))
		{
			return File.getContent(path);
		}
		else
		{
			var context = project.templateContext;
			var hxml = HXML.fromString(context.HAXE_FLAGS);
			hxml.addClassName(context.APP_MAIN);
			switch (targetType)
			{
				case "hl":
					hxml.hl = "_.hl";
				case "neko":
					hxml.neko = "_.n";
				case "java":
					hxml.java = "_";
				case "nodejs":
					hxml.js = "_.js";
				default:
					hxml.cpp = "_";
			}
			hxml.noOutput = true;
			return hxml;
		}
	}

	public override function rebuild():Void
	{
		var commands:Array<Array<String>> = [];

		if (System.hostArchitecture == ARM64 )
		{
			commands.push([
				"-Dlinux",
				"-Drpi",
				"-Dtoolchain=linux",
				"-DBINDIR=LinuxArm64",
				"-DHXCPP_ARM64",
				"-DCXX=aarch64-linux-gnu-g++",
				"-DHXCPP_STRIP=aarch64-linux-gnu-strip",
				"-DHXCPP_AR=aarch64-linux-gnu-ar",
				"-DHXCPP_RANLIB=aarch64-linux-gnu-ranlib"
			]);
		}
		else if (System.hostArchitecture == ARMV7)
		{
			commands.push([
				"-Dlinux",
				"-Drpi",
				"-Dtoolchain=linux",
				"-DBINDIR=LinuxArm",
				"-DHXCPP_M32",
				"-DCXX=arm-linux-gnueabihf-g++",
				"-DHXCPP_STRIP=arm-linux-gnueabihf-strip",
				"-DHXCPP_AR=arm-linux-gnueabihf-ar",
				"-DHXCPP_RANLIB=arm-linux-gnueabihf-ranlib"
			]);
		}
		else if (targetFlags.exists("hl") && System.hostArchitecture == X64)
		{
			// TODO: Support single binary
			commands.push(["-Dlinux", "-DHXCPP_M64", "-Dhashlink"]);
		}
		else
		{
			if (!targetFlags.exists("32") && !targetFlags.exists("x86_32") && System.hostArchitecture == X64)
			{
				commands.push(["-Dlinux", "-DHXCPP_M64"]);
			}

			if (!targetFlags.exists("64") && !targetFlags.exists("x86_64") && (command == "rebuild" || System.hostArchitecture == X86))
			{
				commands.push(["-Dlinux", "-DHXCPP_M32"]);
			}
		}

		if (targetFlags.exists("hl"))
		{
			CPPHelper.rebuild(project, commands, null, "BuildHashlink.xml");
		}

		CPPHelper.rebuild(project, commands);
	}

	public override function run():Void
	{
		var arguments = additionalArguments.copy();

		if (Log.verbose)
		{
			arguments.push("-verbose");
		}

		if (targetType == "nodejs")
		{
			NodeJSHelper.run(project, targetDirectory + "/bin/ApplicationMain.js", arguments);
		}
		else if (targetType == "java")
		{
			System.runCommand(applicationDirectory, "java", ["-jar", project.app.file + ".jar"].concat(arguments));
		}
		else if (project.target == System.hostPlatform)
		{
			arguments = arguments.concat(["-livereload"]);
			System.runCommand(applicationDirectory, "./" + Path.withoutDirectory(executablePath), arguments);
		}
	}

	public override function update():Void
	{
		AssetHelper.processLibraries(project, targetDirectory);

		// project = project.clone ();
		// initialize (project);

		for (asset in project.assets)
		{
			if (asset.embed && asset.sourcePath == "")
			{
				var path = Path.combine(targetDirectory + "/obj/tmp", asset.targetPath);
				System.mkdir(Path.directory(path));
				AssetHelper.copyAsset(asset, path);
				asset.sourcePath = path;
			}
		}

		if (project.targetFlags.exists("xml"))
		{
			project.haxeflags.push("-xml " + targetDirectory + "/types.xml");
		}

		if (project.targetFlags.exists("json"))
		{
			project.haxeflags.push("--json " + targetDirectory + "/types.json");
		}

		var context = generateContext();
		context.OUTPUT_DIR = targetDirectory;

		if (targetType == "cpp" && project.targetFlags.exists("static"))
		{
			for (i in 0...project.ndlls.length)
			{
				var ndll = project.ndlls[i];

				if (ndll.path == null || ndll.path == "")
				{
					context.ndlls[i].path = NDLL.getLibraryPath(ndll, "Linux" + (( System.hostArchitecture == ARMV7 || System.hostArchitecture == ARM64) ? "Arm" : "") + (is64 ? "64" : ""), "lib", ".a", project.debug);
				}
			}
		}

		System.mkdir(targetDirectory);
		System.mkdir(targetDirectory + "/obj");
		System.mkdir(targetDirectory + "/haxe");
		System.mkdir(applicationDirectory);

		// SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");

		ProjectHelper.recursiveSmartCopyTemplate(project, "haxe", targetDirectory + "/haxe", context);
		ProjectHelper.recursiveSmartCopyTemplate(project, targetType + "/hxml", targetDirectory + "/haxe", context);

		if (targetType == "cpp" && project.targetFlags.exists("static"))
		{
			ProjectHelper.recursiveSmartCopyTemplate(project, "cpp/static", targetDirectory + "/obj", context);
		}

		// context.HAS_ICON = IconHelper.createIcon (project.icons, 256, 256, Path.combine (applicationDirectory, "icon.png"));
		for (asset in project.assets)
		{
			var path = Path.combine(applicationDirectory, asset.targetPath);

			if (asset.embed != true)
			{
				if (asset.type != AssetType.TEMPLATE)
				{
					System.mkdir(Path.directory(path));
					AssetHelper.copyAssetIfNewer(asset, path);
				}
				else
				{
					System.mkdir(Path.directory(path));
					AssetHelper.copyAsset(asset, path, context);
				}
			}
		}
	}

	public override function watch():Void
	{
		var hxml = getDisplayHXML();
		var dirs = hxml.getClassPaths(true);

		var outputPath = Path.combine(Sys.getCwd(), project.app.path);
		dirs = dirs.filter(function(dir)
		{
			return (!Path.startsWith(dir, outputPath));
		});

		var command = ProjectHelper.getCurrentCommand();
		System.watch(command, dirs);
	}

	@ignore public override function install():Void {}

	@ignore public override function trace():Void {}

	@ignore public override function uninstall():Void {}
}
