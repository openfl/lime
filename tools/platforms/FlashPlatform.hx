package;

import haxe.Json;
import hxp.Haxelib;
import hxp.HXML;
import hxp.Log;
import hxp.Path;
import hxp.System;
import lime.tools.AssetHelper;
import lime.tools.AssetType;
import lime.tools.DeploymentHelper;
import lime.tools.HXProject;
import lime.tools.ProjectHelper;
import lime.tools.FlashHelper;
import lime.tools.HTML5Helper;
import lime.tools.Orientation;
import lime.tools.Platform;
import lime.tools.PlatformTarget;
import sys.io.File;
import sys.FileSystem;
#if neko
#if haxe4
import sys.thread.Thread;
#else
import neko.vm.Thread;
#end
#end
class FlashPlatform extends PlatformTarget
{
	private var embedded:Bool;
	private var logLength:Int = 0;

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

		for (i in 1...project.windows.length)
		{
			defaults.windows.push(defaults.window);
		}

		defaults.merge(project);
		project = defaults;

		targetDirectory = Path.combine(project.app.path, project.config.getString("flash.output-directory", "flash"));
	}

	public override function build():Void
	{
		System.runCommand("", "haxe", [targetDirectory + "/haxe/" + buildType + ".hxml"]);
	}

	public override function clean():Void
	{
		var targetPath = targetDirectory + "";

		if (FileSystem.exists(targetPath))
		{
			System.removeDirectory(targetPath);
		}
	}

	public override function deploy():Void
	{
		DeploymentHelper.deploy(project, targetFlags, targetDirectory, "Flash");
	}

	public override function display():Void
	{
		if (project.targetFlags.exists("output-file"))
		{
			Sys.println(Path.combine(targetDirectory, "bin/" + project.app.file + ".swf"));
		}
		else
		{
			Sys.println(getDisplayHXML().toString());
		}
	}

	private function generateContext():Dynamic
	{
		// project = project.clone ();

		if (project.targetFlags.exists("xml"))
		{
			project.haxeflags.push("-xml " + targetDirectory + "/types.xml");
		}

		if (Log.verbose)
		{
			project.haxedefs.set("verbose", 1);
		}

		var context = project.templateContext;
		context.WIN_FLASHBACKGROUND = project.window.background != null ? StringTools.hex(project.window.background, 6) : "0xFFFFFF";
		var assets:Array<Dynamic> = cast context.assets;

		for (asset in assets)
		{
			var assetType:AssetType = Reflect.field(AssetType, asset.type.toUpperCase());

			switch (assetType)
			{
				case MUSIC:
					asset.flashClass = "flash.media.Sound";
				case SOUND:
					asset.flashClass = "flash.media.Sound";
				case IMAGE:
					asset.flashClass = "flash.display.BitmapData";
				case FONT:
					asset.flashClass = "flash.text.Font";
				default:
					asset.flashClass = "flash.utils.ByteArray";
			}
		}

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
			hxml.swf = "_.swf";
			hxml.swfVersion = context.SWF_VERSION;
			hxml.noOutput = true;
			return hxml;
		}
	}

	public override function run():Void
	{
		if (traceEnabled)
		{
			FlashHelper.enableLogging();
			logLength = FlashHelper.getLogLength();
		}

		if (project.app.url != null && project.app.url != "")
		{
			System.openURL(project.app.url);
		}
		else
		{
			var destination = targetDirectory + "/bin";
			var targetPath = project.app.file + ".swf";

			if (project.targetFlags.exists("web"))
			{
				HTML5Helper.launch(project, targetDirectory + "/bin");
			}
			else
			{
				if (traceEnabled)
				{
					#if neko
					Thread.create(function()
					{
					#end

						FlashHelper.run(project, destination, targetPath);
						// Sys.exit (0);

					#if neko
					});
					#end

					Sys.sleep(0.1);
				}
				else
				{
					FlashHelper.run(project, destination, targetPath);
				}
			}
		}
	}

	public override function trace():Void
	{
		FlashHelper.enableLogging();
		FlashHelper.tailLog(logLength);
	}

	public override function update():Void
	{
		AssetHelper.processLibraries(project, targetDirectory);

		var destination = targetDirectory + "/bin/";
		System.mkdir(destination);

		// project = project.clone ();

		embedded = FlashHelper.embedAssets(project, targetDirectory);

		var context = generateContext();
		context.OUTPUT_DIR = targetDirectory;

		ProjectHelper.recursiveSmartCopyTemplate(project, "haxe", targetDirectory + "/haxe", context);
		ProjectHelper.recursiveSmartCopyTemplate(project, "flash/hxml", targetDirectory + "/haxe", context);
		ProjectHelper.recursiveSmartCopyTemplate(project, "flash/haxe", targetDirectory + "/haxe", context, true, false);

		if (project.targetFlags.exists("web") || project.app.url != "")
		{
			System.mkdir(destination);
			ProjectHelper.recursiveSmartCopyTemplate(project, "flash/templates/web", destination, generateContext());
		}

		if (embedded)
		{
			var files = ["debug.hxml", "release.hxml", "final.hxml"];
			var path, hxml, lines, output;

			for (file in files)
			{
				path = targetDirectory + "/haxe/" + file;
				hxml = File.getContent(path);

				if (hxml.indexOf("-swf-header") > -1)
				{
					lines = ~/[\r\n]+/g.split(hxml);
					output = [];

					for (line in lines)
					{
						if (line.indexOf("-swf-header") > -1) continue;
						output.push(line);
					}

					if (output.length < lines.length)
					{
						File.saveContent(path, output.join("\n"));
					}
				}
			}
		}

		for (asset in project.assets)
		{
			if (asset.type == AssetType.TEMPLATE || asset.embed == false /*|| !usesLime*/)
			{
				var path = Path.combine(destination, asset.targetPath);

				System.mkdir(Path.directory(path));
				AssetHelper.copyAsset(asset, path, context);
			}
		}
	}

	/*private function getIcon (size:Int, targetPath:String):Void {

		var icon = icons.findIcon (size, size);

		if (icon != "") {

			System.copyIfNewer (icon, targetPath);

		} else {

			icons.updateIcon (size, size, targetPath);

		}

	}*/
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

	@ignore public override function rebuild():Void {}

	@ignore public override function uninstall():Void {}
}
