package;

import hxp.HXML;
import hxp.Log;
import hxp.Path;
import hxp.System;
import haxe.Template;
#if lime
import lime.text.Font;
#end
import lime.tools.AssetHelper;
import lime.tools.AssetType;
import lime.tools.DeploymentHelper;
import lime.tools.ElectronHelper;
import lime.tools.HTML5Helper;
import lime.tools.HXProject;
import lime.tools.Icon;
import lime.tools.IconHelper;
import lime.tools.ModuleHelper;
import lime.tools.Orientation;
import lime.tools.ProjectHelper;
import lime.tools.PlatformTarget;
import sys.io.File;
import sys.FileSystem;

class HTML5Platform extends PlatformTarget
{
	private var dependencyPath:String;
	private var npm:Bool;
	private var outputFile:String;

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

		defaults.window.width = 0;
		defaults.window.height = 0;
		defaults.window.fps = 60;

		for (i in 1...project.windows.length)
		{
			defaults.windows.push(defaults.window);
		}

		defaults.merge(project);
		project = defaults;

		initialize(command, project);
	}

	public override function build():Void
	{
		if (npm)
		{
			if (command == "build")
			{
				var buildCommand = "build:" + (project.targetFlags.exists("final") ? "prod" : "dev");
				System.runCommand(targetDirectory + "/bin", "npm", ["run", buildCommand, "-s"]);
			}
			else
			{
				return;
			}
		}

		ModuleHelper.buildModules(project, targetDirectory + "/obj", targetDirectory + "/bin");

		if (project.app.main != null)
		{
			var type = "release";

			if (project.debug)
			{
				type = "debug";
			}
			else if (project.targetFlags.exists("final"))
			{
				type = "final";
			}

			var hxml = targetDirectory + "/haxe/" + type + ".hxml";
			System.runCommand("", "haxe", [hxml]);

			if (noOutput) return;

			HTML5Helper.encodeSourceMappingURL(targetDirectory + "/bin/" + project.app.file + ".js");

			if (project.targetFlags.exists("webgl"))
			{
				System.copyFile(targetDirectory + "/obj/ApplicationMain.js", outputFile);
			}

			if (project.modules.iterator().hasNext())
			{
				ModuleHelper.patchFile(outputFile);
			}

			if (FileSystem.exists(outputFile))
			{
				var context = project.templateContext;
				context.SOURCE_FILE = File.getContent(outputFile);
				context.embeddedLibraries = [];

				for (dependency in project.dependencies)
				{
					if (dependency.embed && StringTools.endsWith(dependency.path, ".js") && FileSystem.exists(dependency.path))
					{
						var script = File.getContent(dependency.path);
						if (!dependency.allowWebWorkers)
						{
							script = 'if(typeof self === "undefined" || !self.constructor.name.includes("Worker")) { $script }';
						}
						context.embeddedLibraries.push(script);
					}
				}

				System.copyFileTemplate(project.templatePaths, "html5/output.js", outputFile, context);
			}

			if (project.targetFlags.exists("minify") || type == "final")
			{
				HTML5Helper.minify(project, targetDirectory + "/bin/" + project.app.file + ".js");
			}
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
		var name = "HTML5";

		if (targetFlags.exists("electron"))
		{
			name = "Electron";
		}

		DeploymentHelper.deploy(project, targetFlags, targetDirectory, name);
	}

	public override function display():Void
	{
		if (project.targetFlags.exists("output-file"))
		{
			Sys.println(outputFile);
		}
		else
		{
			Sys.println(getDisplayHXML().toString());
		}
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
			hxml.js = "_";
			hxml.define("html");
			if (targetFlags.exists("electron"))
			{
				hxml.define("electron");
			}
			hxml.noOutput = true;
			return hxml;
		}
	}

	private function initialize(command:String, project:HXProject):Void
	{
		if (targetFlags.exists("electron"))
		{
			targetDirectory = Path.combine(project.app.path, project.config.getString("electron.output-directory", "electron"));
		}
		else
		{
			targetDirectory = Path.combine(project.app.path, project.config.getString("html5.output-directory", "html5"));
		}

		dependencyPath = project.config.getString("html5.dependency-path", "lib");
		outputFile = targetDirectory + "/bin/" + project.app.file + ".js";

		try
		{
			if (targetFlags.exists("npm") || (FileSystem.exists(targetDirectory + "/bin/package.json") && !targetFlags.exists("electron")))
			{
				npm = true;
				outputFile = project.app.file + ".js";
			}
		}
		catch (e:Dynamic) {}
	}

	public override function run():Void
	{
		if (npm)
		{
			var runCommand = "start:" + (project.targetFlags.exists("final") ? "prod" : "dev");
			System.runCommand(targetDirectory + "/bin", "npm", ["run", runCommand, "-s"]);
		}
		else if (targetFlags.exists("electron"))
		{
			var npx = targetFlags.exists("npx");
			ElectronHelper.launch(project, targetDirectory + "/bin", npx);
		}
		else
		{
			HTML5Helper.launch(project, targetDirectory + "/bin");
		}
	}

	public override function update():Void
	{
		AssetHelper.processLibraries(project, targetDirectory);

		// project = project.clone ();

		var destination = targetDirectory + "/bin/";
		if (npm) destination += "dist/";
		System.mkdir(destination);

		var webfontDirectory = targetDirectory + "/obj/webfont";
		var useWebfonts = true;

		for (haxelib in project.haxelibs)
		{
			if (haxelib.name == "openfl-html5-dom" || haxelib.name == "openfl-bitfive")
			{
				useWebfonts = false;
			}
		}

		var fontPath:String;

		for (asset in project.assets)
		{
			if (asset.type == AssetType.FONT && asset.targetPath != null)
			{
				if (useWebfonts)
				{
					fontPath = Path.combine(webfontDirectory, Path.withoutDirectory(asset.targetPath));

					if (!FileSystem.exists(fontPath))
					{
						System.mkdir(webfontDirectory);
						System.copyFile(asset.sourcePath, fontPath);

						var originalPath = asset.sourcePath;
						asset.sourcePath = fontPath;

						HTML5Helper.generateWebfonts(project, asset);

						var ext = "." + Path.extension(asset.sourcePath);
						var source = Path.withoutExtension(asset.sourcePath);
						var extensions = [ext, ".eot", ".woff", ".svg"];

						for (extension in extensions)
						{
							if (!FileSystem.exists(source + extension))
							{
								if (extension != ".eot" && extension != ".svg")
								{
									Log.warn("Could not generate *" + extension + " web font for \"" + originalPath + "\"");
								}
							}
						}
					}

					asset.sourcePath = fontPath;
					asset.targetPath = Path.withoutExtension(asset.targetPath);
				}
				else
				{
					// project.haxeflags.push (HTML5Helper.generateFontData (project, asset));
				}
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

		if (Log.verbose)
		{
			project.haxedefs.set("verbose", 1);
		}

		ModuleHelper.updateProject(project);

		var libraryNames = new Map<String, Bool>();

		for (asset in project.assets)
		{
			if (asset.library != null && !libraryNames.exists(asset.library))
			{
				libraryNames[asset.library] = true;
			}
		}

		if (npm)
		{
			var path:String;
			for (i in 0...project.sources.length)
			{
				path = project.sources[i];
				if (StringTools.startsWith(path, targetDirectory) && !FileSystem.exists(Path.directory(path)))
				{
					System.mkdir(Path.directory(path));
				}
				project.sources[i] = Path.tryFullPath(path);
			}
		}

		// for (library in libraryNames.keys ()) {
		//
		// project.haxeflags.push ("-resource " + targetDirectory + "/obj/manifest/" + library + ".json@__ASSET_MANIFEST__" + library);
		//
		// }

		// project.haxeflags.push ("-resource " + targetDirectory + "/obj/manifest/default.json@__ASSET_MANIFEST__default");

		var context = project.templateContext;

		context.WIN_FLASHBACKGROUND = project.window.background != null ? StringTools.hex(project.window.background, 6) : "";
		context.OUTPUT_DIR = npm ? Path.tryFullPath(targetDirectory) : targetDirectory;
		context.OUTPUT_FILE = outputFile;

		if (project.targetFlags.exists("webgl"))
		{
			context.CPP_DIR = targetDirectory + "/obj";
		}

		context.favicons = [];

		var icons = project.icons;

		if (icons.length == 0)
		{
			icons = [new Icon(System.findTemplate(project.templatePaths, "default/icon.svg"))];
		}

		// if (IconHelper.createWindowsIcon (icons, Path.combine (destination, "favicon.ico"))) {
		//
		// context.favicons.push ({ rel: "icon", type: "image/x-icon", href: "./favicon.ico" });
		//
		// }

		if (IconHelper.createIcon(icons, 192, 192, Path.combine(destination, "favicon.png")))
		{
			context.favicons.push({rel: "shortcut icon", type: "image/png", href: "./favicon.png"});
		}

		context.linkedLibraries = [];

		for (dependency in project.dependencies)
		{
			if (!dependency.embed || npm)
			{
				if (StringTools.endsWith(dependency.name, ".js"))
				{
					context.linkedLibraries.push(dependency.name);
				}
				else if (StringTools.endsWith(dependency.path, ".js") && FileSystem.exists(dependency.path))
				{
					var name = Path.withoutDirectory(dependency.path);

					context.linkedLibraries.push("./" + dependencyPath + "/" + name);
					copyIfNewer(dependency.path, Path.combine(destination, Path.combine(dependencyPath, name)));
				}
			}
		}

		var createdDirectories = new Map<String, Bool>();
		var dir:String = null;

		for (asset in project.assets)
		{
			var path = Path.combine(destination, asset.targetPath);

			if (asset.type != AssetType.TEMPLATE)
			{
				if (/*asset.embed != true &&*/ asset.type != AssetType.FONT)
				{
					dir = Path.directory(path);
					if (!createdDirectories.exists(dir))
					{
						System.mkdir(dir);
						createdDirectories.set(dir, true);
					}
					AssetHelper.copyAssetIfNewer(asset, path);
				}
				else if (asset.type == AssetType.FONT && useWebfonts)
				{
					System.mkdir(Path.directory(path));
					var ext = "." + Path.extension(asset.sourcePath);
					var source = Path.withoutExtension(asset.sourcePath);

					var hasFormat = [false, false, false, false];
					var extensions = [ext, ".eot", ".svg", ".woff"];
					var extension:String;

					for (i in 0...extensions.length)
					{
						extension = extensions[i];

						if (FileSystem.exists(source + extension))
						{
							System.copyIfNewer(source + extension, path + extension);
							hasFormat[i] = true;
						}
					}

					var shouldEmbedFont = false;

					for (embedded in hasFormat)
					{
						if (embedded) shouldEmbedFont = true;
					}

					var embeddedAssets:Array<Dynamic> = cast context.assets;
					for (embeddedAsset in embeddedAssets)
					{
						if (embeddedAsset.type == "font" && embeddedAsset.sourcePath == asset.sourcePath)
						{
							#if lime
							var font = Font.fromFile(asset.sourcePath);

							embeddedAsset.ascender = font.ascender;
							embeddedAsset.descender = font.descender;
							embeddedAsset.height = font.height;
							embeddedAsset.numGlyphs = font.numGlyphs;
							embeddedAsset.underlinePosition = font.underlinePosition;
							embeddedAsset.underlineThickness = font.underlineThickness;
							embeddedAsset.unitsPerEM = font.unitsPerEM;

							if (shouldEmbedFont)
							{
								var urls:Array<String> = [];
								if (hasFormat[1]) urls.push("url('" + embeddedAsset.targetPath + ".eot?#iefix') format('embedded-opentype')");
								if (hasFormat[3]) urls.push("url('" + embeddedAsset.targetPath + ".woff') format('woff')");
								urls.push("url('" + embeddedAsset.targetPath + ext + "') format('truetype')");
								if (hasFormat[2]) urls.push("url('" + embeddedAsset.targetPath + ".svg#" + StringTools.urlEncode(embeddedAsset.fontName)
									+ "') format('svg')");

								var fontFace = "\t\t@font-face {\n";
								fontFace += "\t\t\tfont-family: '" + embeddedAsset.fontName + "';\n";
								// if (hasFormat[1]) fontFace += "\t\t\tsrc: url('" + embeddedAsset.targetPath + ".eot');\n";
								fontFace += "\t\t\tsrc: " + urls.join(",\n\t\t\t") + ";\n";
								fontFace += "\t\t\tfont-weight: normal;\n";
								fontFace += "\t\t\tfont-style: normal;\n";
								fontFace += "\t\t}\n";

								embeddedAsset.cssFontFace = fontFace;
							}
							break;
							#end
						}
					}
				}
			}
		}

		ProjectHelper.recursiveSmartCopyTemplate(project, "html5/template", destination, context);

		if (project.app.main != null)
		{
			ProjectHelper.recursiveSmartCopyTemplate(project, "haxe", targetDirectory + "/haxe", context);
			ProjectHelper.recursiveSmartCopyTemplate(project, "html5/haxe", targetDirectory + "/haxe", context, true, false);
			ProjectHelper.recursiveSmartCopyTemplate(project, "html5/hxml", targetDirectory + "/haxe", context);
		}

		if (npm)
		{
			ProjectHelper.recursiveSmartCopyTemplate(project, "html5/npm", targetDirectory + "/bin", context);
			if (!FileSystem.exists(targetDirectory + "/bin/node_modules"))
			{
				System.runCommand(targetDirectory + "/bin", "npm", ["install", "-s"]);
			}
		}

		if (targetFlags.exists("electron"))
		{
			ProjectHelper.recursiveSmartCopyTemplate(project, "electron/template", destination, context);

			if (project.app.main != null)
			{
				ProjectHelper.recursiveSmartCopyTemplate(project, "electron/haxe", targetDirectory + "/haxe", context, true, false);
				ProjectHelper.recursiveSmartCopyTemplate(project, "electron/hxml", targetDirectory + "/haxe", context);
			}
		}

		for (asset in project.assets)
		{
			var path = Path.combine(destination, asset.targetPath);

			if (asset.type == AssetType.TEMPLATE)
			{
				System.mkdir(Path.directory(path));
				AssetHelper.copyAsset(asset, path, context);
			}
		}
	}

	public override function watch():Void
	{
		// TODO: Use a custom live reload HTTP server for test/run instead

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

	@ignore public override function trace():Void {}

	@ignore public override function uninstall():Void {}
}
