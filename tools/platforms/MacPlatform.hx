package;

import haxe.io.Eof;
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
import lime.tools.HashlinkHelper;
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
import sys.io.Process;
import sys.FileSystem;

class MacPlatform extends PlatformTarget
{
	private var applicationDirectory:String;
	private var contentDirectory:String;
	private var executableDirectory:String;
	private var executablePath:String;
	private var targetArchitecture:Architecture;
	private var targetType:String;

	private var dirSuffix(get, never):String;

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

		targetArchitecture = Type.createEnum(Architecture, Type.enumConstructor(System.hostArchitecture));
		for (architecture in project.architectures)
		{
			if (architecture.match(X86 | X64 | ARMV6 | ARMV7 | ARM64))
			{
				targetArchitecture = architecture;
				break;
			}
		}

		if (project.targetFlags.exists("neko") || project.target != System.hostPlatform)
		{
			targetType = "neko";
		}
		else if (project.targetFlags.exists("hl") || project.targetFlags.exists("hlc"))
		{
			targetType = "hl";
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

		var defaultTargetDirectory = switch (targetType)
		{
			case "cpp": "macos";
			case "hl": project.targetFlags.exists("hlc") ? "hlc" : targetType;
			default: targetType;
		}
		targetDirectory = Path.combine(project.app.path, project.config.getString("mac.output-directory", defaultTargetDirectory));
		targetDirectory = StringTools.replace(targetDirectory, "arch64", dirSuffix);
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
					ProjectHelper.copyLibrary(project, ndll, "Mac" + dirSuffix, "", ".hdll", executableDirectory, project.debug, targetSuffix);
				}
				else
				{
					ProjectHelper.copyLibrary(project, ndll, "Mac" + dirSuffix, "",
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

			NekoHelper.createExecutable(project.templatePaths, "mac" + dirSuffix.toLowerCase(), targetDirectory + "/obj/ApplicationMain.n", executablePath);
			NekoHelper.copyLibraries(project.templatePaths, "mac" + dirSuffix.toLowerCase(), executableDirectory);
		}
		else if (targetType == "hl")
		{
			System.runCommand("", "haxe", [hxml]);

			if (noOutput) return;

			// ensure that the shell script is replaced by the template executable
			System.deleteFile(executablePath);

			HashlinkHelper.copyHashlink(project, targetDirectory, executableDirectory, executablePath, true);

			if (project.targetFlags.exists("hlc"))
			{
				var compiler = project.targetFlags.exists("clang") ? "clang" : "gcc";
				// the libraries were compiled as x86_64, so if the build is
				// happening on ARM64 instead, we need to ensure that the
				// same architecture is used for the executable, so we wrap our
				// compiler command with the `arch -x86_64` command.
				// if we ever support ARM or Universal binaries, this will
				// need to be handled differently.
				var command = ["arch", "-x86_64", compiler, "-O3", "-o", executablePath, "-std=c11", "-Wl,-rpath,@executable_path", "-I", Path.combine(targetDirectory, "obj"), Path.combine(targetDirectory, "obj/ApplicationMain.c")];
				for (file in System.readDirectory(executableDirectory))
				{
					switch Path.extension(file)
					{
						case "dylib", "hdll":
							// ensure the executable knows about every library
							command.push(file);
						default:
					}
				}
				System.runCommand("", command.shift(), command);

				for (file in System.readDirectory(executableDirectory))
				{
					switch Path.extension(file)
					{
						case "dylib", "hdll":
							// when launched inside an .app file, the executable
							// can't find the library files unless we tell
							// it to search specifically from @executable_path
							System.runCommand("", "install_name_tool", ["-change", Path.withoutDirectory(file), "@executable_path/" + Path.withoutDirectory(file), executablePath]);
						default:
					}
				}
			}
			else
			{
				// HashLink JIT looks for hlboot.dat and libraries in the current
				// working directory, so the .app file won't work properly if it
				// tries to run the HashLink executable directly.
				// when the .app file is launched, we can tell it to run a shell
				// script instead of the HashLink executable. the shell script
				// tells the HL where to find everything.

				// we want to keep the original "hl" file name because our
				// shell script will use the app name
				var hlExecutablePath = Path.combine(executableDirectory, "hl");
				System.renameFile(executablePath, hlExecutablePath);
				System.runCommand("", "chmod", ["755", hlExecutablePath]);

				// then we can use the executable name for the shell script
				System.copyFileTemplate(project.templatePaths, 'hl/mac-launch.sh', executablePath);
				System.runCommand("", "chmod", ["755", executablePath]);
			}
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
			JavaHelper.copyLibraries(project.templatePaths, "Mac" + dirSuffix, executableDirectory);
		}
		else if (targetType == "nodejs")
		{
			System.runCommand("", "haxe", [hxml]);

			if (noOutput) return;

			// NekoHelper.createExecutable (project.templatePaths, "Mac" + dirSuffix, targetDirectory + "/obj/ApplicationMain.n", executablePath);
			// NekoHelper.copyLibraries (project.templatePaths, "Mac" + dirSuffix, executableDirectory);
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

			if (targetArchitecture == X64)
			{
				haxeArgs.push("-D");
				haxeArgs.push("HXCPP_M64");
				flags.push("-DHXCPP_M64");
			}
			else if (targetArchitecture == ARM64)
			{
				haxeArgs.push("-D");
				haxeArgs.push("HXCPP_ARM64");
				flags.push("-DHXCPP_ARM64");
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

		if (System.hostPlatform != WINDOWS && targetType != "nodejs" && targetType != "java" && sys.FileSystem.exists(executablePath))
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
		context.HL_FILE = targetDirectory + "/obj/ApplicationMain" + (project.defines.exists("hlc") ? ".c" : ".hl");
		context.CPP_DIR = targetDirectory + "/obj/";
		context.BUILD_DIR = project.app.path + "/mac" + dirSuffix.toLowerCase();

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

		switch (System.hostArchitecture)
		{
			case X64:
				if (targetFlags.exists("hl"))
				{
					// TODO: Support single binary
					commands.push(["-Dmac", "-DHXCPP_CLANG", "-DHXCPP_M64", "-Dhashlink"]);
				}
				else if (targetFlags.exists("arm64"))
				{
					commands.push(["-Dmac", "-DHXCPP_CLANG", "-DHXCPP_ARM64"]);
				}
				else if (!targetFlags.exists("32") && !targetFlags.exists("x86_32"))
				{
					commands.push(["-Dmac", "-DHXCPP_CLANG", "-DHXCPP_M64"]);
				}
				else
				{
					commands.push(["-Dmac", "-DHXCPP_CLANG", "-DHXCPP_M32"]);
				}
			case X86:
				commands.push(["-Dmac", "-DHXCPP_CLANG", "-DHXCPP_M32"]);
			case ARM64:
				if (targetFlags.exists("hl"))
				{
					// hashlink doesn't support arm64 macs yet
					commands.push(["-Dmac", "-DHXCPP_CLANG", "-DHXCPP_ARCH=x86_64", "-Dhashlink"]);
				}
				else if (targetFlags.exists("64") || targetFlags.exists("x86_64"))
				{
					commands.push(["-Dmac", "-DHXCPP_CLANG", "-DHXCPP_ARCH=x86_64"]);
				}
				else
				{
					commands.push(["-Dmac", "-DHXCPP_CLANG", "-DHXCPP_ARM64"]);
				}
			default:
		}

		if (targetFlags.exists("hl"))
		{
			CPPHelper.rebuild(project, commands, null, "BuildHashlink.xml");
			copyAndFixHashLinkHomebrewDependencies();
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
		else if (project.target == System.hostPlatform)
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

		if (project.targetFlags.exists("json"))
		{
			project.haxeflags.push("--json " + targetDirectory + "/types.json");
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
					context.ndlls[i].path = NDLL.getLibraryPath(ndll, "Mac" + dirSuffix, "lib", ".a", project.debug);
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

	// Getters & Setters

	private inline function get_dirSuffix():String
	{
		if (targetFlags.exists("hl"))
		{
			// hashlink doesn't support arm64 macs yet
			return "64";
		}
		return targetArchitecture == X64 ? "64" : targetArchitecture == ARM64 ? "Arm64" : "";
	}

	/**
		Finds and copies all Homebrew dependencies of the HashLink executable,
		its .hdll files, and its .dylib files. We need to bundle these
		dependencies, or the resulting .app file won't launch on systems that
		don't have them installed. We also don't want to have to ask random
		users to install Homebrew and the dependencies manually.

		This process involves copying the dependencies to the same directory as
		our bundled HashLink executable. Then, we use install_name_tool to
		update the paths to those dependencies. We change the paths to use
		@executable_path so that they can be found in the .app bundle and not at
		their original locations.
	**/
	private function copyAndFixHashLinkHomebrewDependencies():Void
	{
		var limeDirectory = Haxelib.getPath(new Haxelib("lime"), true);
		var bindir = "Mac64";
		var bundledHLDirectory = Path.combine(limeDirectory, 'templates/bin/hl/$bindir');
		if (!FileSystem.exists(bundledHLDirectory))
		{
			Log.error('Directory does not exist: $bundledHLDirectory');
			return;
		}
		if (!FileSystem.isDirectory(bundledHLDirectory))
		{
			Log.error('Not a directory: $bundledHLDirectory');
			return;
		}

		// these are the known directories where Homebrew installs its dependencies
		// we may need to add more in the future, but this seems to be enough for now
		var homebrewDirs = [
			"/usr/local/opt/",
			"/usr/local/Cellar/"
		];

		// first, collect all executables, hdlls, and dylibs that were built
		// by BuildHashlink.xml
		var bundledPaths:Array<String> = [];
		for (fileName in FileSystem.readDirectory(bundledHLDirectory))
		{
			var ext = Path.extension(fileName);
			if (ext != "dylib" && ext != "hdll" && fileName != "hl")
			{
				// ignore files that aren't executables or libraries
				continue;
			}
			var srcPath = Path.join([bundledHLDirectory, fileName]);
			bundledPaths.push(srcPath);
		}

		var homebrewDependencyPaths:Array<String> = [];

		// then find and copy all dependencies of those executables/libraries
		// that come from Homebrew. keep searching all newly found Homebrew
		// libraries for additional Homebrew dependendencies too.
		var pathsToSearchForHomebrewDependencies = bundledPaths.copy();
		while (pathsToSearchForHomebrewDependencies.length > 0)
		{
			var srcPath = pathsToSearchForHomebrewDependencies.shift();
			var destPath = Path.join([bundledHLDirectory, Path.withoutDirectory(srcPath)]);
			if (bundledPaths.indexOf(srcPath) == -1)
			{
				// copy files that don't exist yet
				File.copy(srcPath, destPath);
			}

			var process = new Process("otool", ["-L", destPath]);
			var exitCode = process.exitCode(true);
			if (exitCode != 0)
			{
				Log.error('otool -L process exited with code: <${exitCode}> for file <${destPath}>');
				continue;
			}

			while (true)
			{
				try
				{
					var line = process.stdout.readLine();
					var ereg = ~/^\s+(.+?\.\w+?)\s\(/;
					if (ereg.match(line))
					{
						var libPath = StringTools.trim(ereg.matched(1));
						if (homebrewDependencyPaths.indexOf(libPath) != -1)
						{
							// already processed this file
							continue;
						}
						var resolvedLibPath = libPath;
						if (StringTools.startsWith(libPath, "@rpath/"))
						{
							resolvedLibPath = Path.join([Path.directory(srcPath), Path.withoutDirectory(libPath)]);
							if (!FileSystem.exists(resolvedLibPath))
							{
								Log.error("Failed to resolve library to real path: " + libPath);
								continue;
							}
						}
						if (Lambda.exists(homebrewDirs, function(dirPath:String):Bool { return StringTools.startsWith(resolvedLibPath, dirPath); }))
						{
							homebrewDependencyPaths.push(libPath);
							pathsToSearchForHomebrewDependencies.push(resolvedLibPath);
						}
					}
				}
				catch (e:Eof)
				{
					// no more output
					break;
				}
			}
		}

		// finally, go through all executables and libraries that were either
		// built by BuildHashlink.xml or were copied in the previous step,
		// and replace any Homebrew library paths with @executable_path.
		for (fileName in FileSystem.readDirectory(bundledHLDirectory))
		{
			var ext = Path.extension(fileName);
			var isLibrary = ext == "dylib" || ext == "hdll";

			if (fileName != "hl" && !isLibrary)
			{
				// ignore files that aren't executables or libraries
				continue;
			}

			var absoluteFilePath = Path.join([bundledHLDirectory, fileName]);

			if (isLibrary)
			{
				var newId = "@executable_path/" + fileName;
				System.runCommand("", "install_name_tool", ["-id", newId, absoluteFilePath]);
			}

			for (homebrewPath in homebrewDependencyPaths)
			{
				var newPath = "@executable_path/" + Path.withoutDirectory(homebrewPath);
				System.runCommand("", "install_name_tool", ["-change", homebrewPath, newPath, absoluteFilePath]);
			}
		}
	}
}
