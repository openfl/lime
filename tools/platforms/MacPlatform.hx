package;

import lime.tools.HashlinkHelper;
import hxp.Haxelib;
import hxp.HXML;
import hxp.Log;
import hxp.Path;
import hxp.NDLL;
import hxp.System;
import lime.tools.Architecture;
import lime.tools.AssetHelper;
import lime.tools.AssetType;
import lime.tools.CPPHelper;
import lime.tools.CSHelper;
import lime.tools.DeploymentHelper;
import lime.tools.GUID;
import lime.tools.HXProject;
import lime.tools.Icon;
import lime.tools.IconHelper;
import lime.tools.JavaHelper;
import lime.tools.NekoHelper;
import lime.tools.NodeJSHelper;
import lime.tools.Orientation;
import lime.tools.Platform;
import lime.tools.PlatformTarget;
import lime.tools.ProjectHelper;
import sys.io.File;
import sys.FileSystem;

class MacPlatform extends PlatformTarget
{
	private var applicationDirectory:String;
	private var contentDirectory:String;
	private var executableDirectory:String;
	private var executablePath:String;
	private var is64:Bool;
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
			if (architecture == Architecture.X64)
			{
				is64 = true;
			}
		}

		if (project.targetFlags.exists("neko") || project.target != cast System.hostPlatform)
		{
			targetType = "neko";
		}
		else if (project.targetFlags.exists("hl"))
		{
			targetType = "hl";
			is64 = true;
		}
		else if (project.targetFlags.exists("java"))
		{
			targetType = "java";
		}
		else if (project.targetFlags.exists("nodejs"))
		{
			targetType = "nodejs";
		}
		else if (project.targetFlags.exists("cs"))
		{
			targetType = "cs";
		}
		else
		{
			targetType = "cpp";
		}

		targetDirectory = Path.combine(project.app.path, project.config.getString("mac.output-directory", targetType == "cpp" ? "macos" : targetType));
		targetDirectory = StringTools.replace(targetDirectory, "arch64", is64 ? "64" : "");
		applicationDirectory = targetDirectory + "/bin/" + project.app.file + ".app";
		contentDirectory = applicationDirectory + "/Contents/Resources";
		executableDirectory = applicationDirectory + "/Contents/MacOS";
		executablePath = executableDirectory + "/" + project.app.file;
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
					ProjectHelper.copyLibrary(project, ndll, "Mac" + (is64 ? "64" : ""), "", ".hdll", executableDirectory, project.debug, targetSuffix);
				}
				else
				{
					ProjectHelper.copyLibrary(project, ndll, "Mac" + (is64 ? "64" : ""), "",
						(ndll.haxelib != null
							&& (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dll" : ".ndll", executableDirectory,
						project.debug, targetSuffix);
				}
			}
		}

		if (targetType == "neko")
		{
			System.runCommand("", "haxe", [hxml]);

			if (noOutput) return;

			NekoHelper.createExecutable(project.templatePaths, "mac" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
			NekoHelper.copyLibraries(project.templatePaths, "mac" + (is64 ? "64" : ""), executableDirectory);
		}
		else if (targetType == "hl")
		{
			System.runCommand("", "haxe", [hxml]);

			if (noOutput) return;

			HashlinkHelper.copyHashlink(project, targetDirectory, executableDirectory, executablePath, is64);

			// HashLink looks for hlboot.dat and libraries in the current
			// working directory, so the .app file won't work properly if it
			// tries to run the HashLink executable directly.
			// when the .app file is launched, we can tell it to run a shell
			// script instead of the HashLink executable. the shell script will
			// adjusts the working directory before running the HL executable.

			// unlike other platforms, we want to use the original "hl" name
			var hlExecutablePath = Path.combine(executableDirectory, "hl");
			System.renameFile(executablePath, hlExecutablePath);
			System.runCommand("", "chmod", ["755", hlExecutablePath]);
			// then we can use the executable name for the shell script
			System.copyFileTemplate(project.templatePaths, 'hl/mac-launch.sh', executablePath);
		}
		else if (targetType == "java")
		{
			var libPath = Path.combine(Haxelib.getPath(new Haxelib("lime")), "templates/java/lib/");

			System.runCommand("", "haxe", [hxml, "-java-lib", libPath + "disruptor.jar", "-java-lib", libPath + "lwjgl.jar"]);

			if (noOutput) return;

			Haxelib.runCommand(targetDirectory + "/obj", ["run", "hxjava", "hxjava_build.txt", "--haxe-version", "3103"]);
			System.recursiveCopy(targetDirectory + "/obj/lib", Path.combine(executableDirectory, "lib"));
			System.copyFile(targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-Debug" : "") + ".jar",
				Path.combine(executableDirectory, project.app.file + ".jar"));
			JavaHelper.copyLibraries(project.templatePaths, "Mac" + (is64 ? "64" : ""), executableDirectory);
		}
		else if (targetType == "nodejs")
		{
			System.runCommand("", "haxe", [hxml]);

			if (noOutput) return;

			// NekoHelper.createExecutable (project.templatePaths, "Mac" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
			// NekoHelper.copyLibraries (project.templatePaths, "Mac" + (is64 ? "64" : ""), executableDirectory);
		}
		else if (targetType == "cs")
		{
			System.runCommand("", "haxe", [hxml]);

			if (noOutput) return;

			CSHelper.copySourceFiles(project.templatePaths, targetDirectory + "/obj/src");
			var txtPath = targetDirectory + "/obj/hxcs_build.txt";
			CSHelper.addSourceFiles(txtPath, CSHelper.ndllSourceFiles);
			CSHelper.addGUID(txtPath, GUID.uuid());
			CSHelper.compile(project, targetDirectory + "/obj", targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), "x64", "desktop");
			System.copyFile(targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", executablePath + ".exe");
			File.saveContent(executablePath, "#!/bin/sh\nmono ${PWD}/" + project.app.file + ".exe");
		}
		else
		{
			var haxeArgs = [hxml, "-D", "HXCPP_CLANG"];
			var flags = ["-DHXCPP_CLANG"];

			if (is64)
			{
				haxeArgs.push("-D");
				haxeArgs.push("HXCPP_M64");
				flags.push("-DHXCPP_M64");
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

		if (System.hostPlatform != WINDOWS && targetType != "nodejs" && targetType != "java")
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
		DeploymentHelper.deploy(project, targetFlags, targetDirectory, "Mac");
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
		var context = project.templateContext;
		context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
		context.NODE_FILE = executableDirectory + "/ApplicationMain.js";
		context.HL_FILE = targetDirectory + "/obj/ApplicationMain.hl";
		context.CPP_DIR = targetDirectory + "/obj/";
		context.BUILD_DIR = project.app.path + "/mac" + (is64 ? "64" : "");

		return context;
	}

	private function getDisplayHXML():HXML
	{
		var path = targetDirectory + "/haxe/" + buildType + ".hxml";

		if (FileSystem.exists(path))
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
		var commands = [];

		if (targetFlags.exists("hl") && System.hostArchitecture == X64)
		{
			// TODO: Support single binary
			commands.push(["-Dmac", "-DHXCPP_CLANG", "-DHXCPP_M64", "-Dhashlink"]);
		}
		else
		{
			if (!targetFlags.exists("32") && (command == "rebuild" || System.hostArchitecture == X64))
			{
				commands.push(["-Dmac", "-DHXCPP_CLANG", "-DHXCPP_M64"]);
			}

			if (!targetFlags.exists("64") && (targetFlags.exists("32") || System.hostArchitecture == X86))
			{
				commands.push(["-Dmac", "-DHXCPP_CLANG", "-DHXCPP_M32"]);
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
			NodeJSHelper.run(project, executableDirectory + "/ApplicationMain.js", arguments);
		}
		else if (targetType == "java")
		{
			System.runCommand(executableDirectory, "java", ["-jar", project.app.file + ".jar"].concat(arguments));
		}
		else if (project.target == cast System.hostPlatform)
		{
			arguments = arguments.concat(["-livereload"]);
			System.runCommand(executableDirectory, "./" + Path.withoutDirectory(executablePath), arguments);
		}
	}

	public override function update():Void
	{
		AssetHelper.processLibraries(project, targetDirectory);

		// project = project.clone ();

		if (project.targetFlags.exists("xml"))
		{
			project.haxeflags.push("-xml " + targetDirectory + "/types.xml");
		}

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

		var context = generateContext();
		context.OUTPUT_DIR = targetDirectory;

		if (targetType == "cpp" && project.targetFlags.exists("static"))
		{
			for (i in 0...project.ndlls.length)
			{
				var ndll = project.ndlls[i];

				if (ndll.path == null || ndll.path == "")
				{
					context.ndlls[i].path = NDLL.getLibraryPath(ndll, "Mac" + (is64 ? "64" : ""), "lib", ".a", project.debug);
				}
			}
		}

		System.mkdir(targetDirectory);
		System.mkdir(targetDirectory + "/obj");
		System.mkdir(targetDirectory + "/haxe");
		System.mkdir(applicationDirectory);
		System.mkdir(contentDirectory);

		// SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");

		ProjectHelper.recursiveSmartCopyTemplate(project, "haxe", targetDirectory + "/haxe", context);
		ProjectHelper.recursiveSmartCopyTemplate(project, targetType + "/hxml", targetDirectory + "/haxe", context);

		if (targetType == "cpp" && project.targetFlags.exists("static"))
		{
			ProjectHelper.recursiveSmartCopyTemplate(project, "cpp/static", targetDirectory + "/obj", context);
		}

		System.copyFileTemplate(project.templatePaths, "mac/Info.plist", targetDirectory + "/bin/" + project.app.file + ".app/Contents/Info.plist", context);
		System.copyFileTemplate(project.templatePaths, "mac/Entitlements.plist",
			targetDirectory
			+ "/bin/"
			+ project.app.file
			+ ".app/Contents/Entitlements.plist", context);

		var icons = project.icons;

		if (icons.length == 0)
		{
			icons = [new Icon(System.findTemplate(project.templatePaths, "default/icon.svg"))];
		}

		context.HAS_ICON = IconHelper.createMacIcon(icons, Path.combine(contentDirectory, "icon.icns"));

		for (asset in project.assets)
		{
			if (asset.embed != true)
			{
				if (asset.type != AssetType.TEMPLATE)
				{
					System.mkdir(Path.directory(Path.combine(contentDirectory, asset.targetPath)));
					AssetHelper.copyAssetIfNewer(asset, Path.combine(contentDirectory, asset.targetPath));
				}
				else
				{
					System.mkdir(Path.directory(Path.combine(targetDirectory, asset.targetPath)));
					AssetHelper.copyAsset(asset, Path.combine(targetDirectory, asset.targetPath), context);
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
