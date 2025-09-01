package;

import hxp.HXML;
import hxp.Path;
import hxp.System;
import lime.tools.Architecture;
import lime.tools.AssetHelper;
import lime.tools.AssetType;
import lime.tools.CPPHelper;
import lime.tools.DeploymentHelper;
import lime.tools.HXProject;
import lime.tools.Icon;
import lime.tools.IconHelper;
import lime.tools.PlatformTarget;
import lime.tools.ProjectHelper;
import lime.tools.TizenHelper;
import sys.io.File;
import sys.FileSystem;

class TizenPlatform extends PlatformTarget
{
	private static var uuid:String = null;

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

		defaults.architectures = [Architecture.ARMV6];
		defaults.window.width = 0;
		defaults.window.height = 0;
		defaults.window.fullscreen = true;
		defaults.window.requireShaders = true;
		= defaults.window.allowHighDPI = false;

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

		targetDirectory = Path.combine(project.app.path, project.config.getString("tizen.output-directory", "tizen"));
	}

	public override function build():Void
	{
		var destination = targetDirectory + "/bin/";

		var arch = "";

		if (project.targetFlags.exists("simulator"))
		{
			arch = "-x86";
		}

		for (ndll in project.ndlls)
		{
			ProjectHelper.copyLibrary(project, ndll, "Tizen", "", arch + ".so", destination + "lib/", project.debug, ".so");
		}

		var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";

		System.runCommand("", "haxe", [hxml, "-D", "tizen"]);

		if (noOutput) return;

		var args = ["-Dtizen", "-DAPP_ID=" + TizenHelper.getUUID(project)];

		if (project.targetFlags.exists("simulator"))
		{
			args.push("-Dsimulator");
		}

		CPPHelper.compile(project, targetDirectory + "/obj", args);
		System.copyIfNewer(targetDirectory
			+ "/obj/ApplicationMain"
			+ (project.debug ? "-debug" : "")
			+ ".exe",
			targetDirectory
			+ "/bin/CommandLineBuild/"
			+ project.app.file
			+ ".exe");
		TizenHelper.createPackage(project, targetDirectory + "/bin/CommandLineBuild", "");
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
		DeploymentHelper.deploy(project, targetFlags, targetDirectory, "Tizen");
	}

	public override function display():Void
	{
		var path = targetDirectory + "/haxe/" + buildType + ".hxml";

		if (FileSystem.exists(path))
		{
			return File.getContent(path);
		}
		else
		{
			var context = project.templateContext;
			var hxml = new HXML();
			hxml.noOutput = true;
			hxml.cpp = "_";
			return context.HAXE_FLAGS + "\n" + hxml.toString();
		}
	}

	public override function rebuild():Void
	{
		var device = (command == "rebuild" || !targetFlags.exists("simulator"));
		var simulator = (command == "rebuild" || targetFlags.exists("simulator"));

		var commands = [];

		if (device) commands.push(["-Dtizen"]);
		if (simulator) commands.push(["-Dtizen", "-Dsimulator"]);

		CPPHelper.rebuild(project, commands);
	}

	public override function run():Void
	{
		TizenHelper.install(project, targetDirectory + "/bin/CommandLineBuild");
		TizenHelper.launch(project);
	}

	public override function trace():Void
	{
		TizenHelper.trace(project);
	}

	public override function update():Void
	{
		AssetHelper.processLibraries(project, targetDirectory);

		// project = project.clone ();

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

		var destination = targetDirectory + "/bin/";
		System.mkdir(destination);

		for (asset in project.assets)
		{
			asset.resourceName = "../res/" + asset.resourceName;
		}

		if (project.targetFlags.exists("xml"))
		{
			project.haxeflags.push("-xml " + targetDirectory + "/types.xml");
		}

		var context = project.templateContext;
		context.CPP_DIR = targetDirectory + "/obj";
		context.OUTPUT_DIR = targetDirectory;
		context.APP_PACKAGE = TizenHelper.getUUID(project);
		context.SIMULATOR = project.targetFlags.exists("simulator");

		System.mkdir(destination + "shared/res/screen-density-xhigh");

		var icons = project.icons;

		if (icons.length == 0)
		{
			icons = [new Icon(System.findTemplate(project.templatePaths, "default/icon.svg"))];
		}

		if (IconHelper.createIcon(icons, 117, 117, Path.combine(destination + "shared/res/screen-density-xhigh", "mainmenu.png")))
		{
			context.APP_ICON = "mainmenu.png";
		}

		ProjectHelper.recursiveSmartCopyTemplate(project, "tizen/template", destination, context);
		ProjectHelper.recursiveSmartCopyTemplate(project, "haxe", targetDirectory + "/haxe", context);
		ProjectHelper.recursiveSmartCopyTemplate(project, "tizen/hxml", targetDirectory + "/haxe", context);

		for (asset in project.assets)
		{
			var path = Path.combine(destination + "res/", asset.targetPath);

			System.mkdir(Path.directory(path));

			if (asset.type != AssetType.TEMPLATE)
			{
				if (asset.targetPath == "/appinfo.json")
				{
					AssetHelper.copyAsset(asset, path, context);
				}
				else
				{
					// going to root directory now, but should it be a forced "assets" folder later?

					AssetHelper.copyAssetIfNewer(asset, path);
				}
			}
			else
			{
				AssetHelper.copyAsset(asset, path, context);
			}
		}
	}

	@ignore public override function install():Void {}

	@ignore public override function uninstall():Void {}
}
