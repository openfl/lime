package;


import hxp.Path;
import haxe.Template;
#if lime
import lime.text.Font;
#end
import lime.tools.AssetHelper;
import lime.tools.AssetType;
import lime.tools.DeploymentHelper;
import lime.tools.ElectronHelper;
import hxp.System;
import lime.tools.HTML5Helper;
import lime.tools.Icon;
import lime.tools.IconHelper;
import hxp.Log;
import lime.tools.ModuleHelper;
import lime.tools.ProjectHelper;
import hxp.Path;
import lime.tools.PlatformTarget;
import hxp.System;
import lime.tools.HXProject;
import hxp.System;
import sys.io.File;
import sys.FileSystem;


class HTML5Platform extends PlatformTarget {


	private var dependencyPath:String;
	private var outputFile:String;
	private var electronMain:String;


	public function new (command:String, _project:HXProject, targetFlags:Map<String, String> ) {

		super (command, _project, targetFlags);

		initialize (command, _project);

	}


	public override function build ():Void {

		ModuleHelper.buildModules (project, targetDirectory + "/obj", targetDirectory + "/bin");

		if (project.app.main != null) {

			var type = "release";

			if (project.debug) {

				type = "debug";

			} else if (project.targetFlags.exists ("final")) {

				type = "final";

			}

			var hxml = targetDirectory + "/haxe/" + type + ".hxml";
			System.runCommand ("", "haxe", [ hxml ] );

			if (noOutput) return;

			HTML5Helper.encodeSourceMappingURL (targetDirectory + "/bin/" + project.app.file + ".js");

			if (project.targetFlags.exists ("webgl")) {

				System.copyFile (targetDirectory + "/obj/ApplicationMain.js", outputFile);

			}

			if (project.modules.iterator ().hasNext ()) {

				ModuleHelper.patchFile (outputFile);

			}

			if (project.targetFlags.exists ("minify") || type == "final") {

				HTML5Helper.minify (project, targetDirectory + "/bin/" + project.app.file + ".js");

			}

		}

	}


	public override function clean ():Void {

		if (FileSystem.exists (targetDirectory)) {

			System.removeDirectory (targetDirectory);

		}

	}


	public override function deploy ():Void {

		var name = "HTML5";

		if (targetFlags.exists ("electron")) {

			name = "Electron";

		}

		DeploymentHelper.deploy (project, targetFlags, targetDirectory, name);

	}


	public override function display ():Void {

		Sys.println (getDisplayHXML ());

	}


	private function getDisplayHXML ():String {

		var type = "html5";

		if (targetFlags.exists ("electron")) {

			type = "electron";

		}

		var hxml = System.findTemplate (project.templatePaths, type + "/hxml/" + buildType + ".hxml");

		var context = project.templateContext;
		context.OUTPUT_DIR = targetDirectory;
		context.OUTPUT_FILE = outputFile;

		var template = new Template (File.getContent (hxml));

		return template.execute (context);

	}


	private function initialize (command:String, project:HXProject):Void {

		if (targetFlags.exists ("electron")) {

			targetDirectory = Path.combine (project.app.path, project.config.getString ("electron.output-directory", "electron"));
			electronMain = project.config.getString ("electron.electron-main", null);

		} else {

			targetDirectory = Path.combine (project.app.path, project.config.getString ("html5.output-directory", "html5"));

		}

		dependencyPath = project.config.getString ("html5.dependency-path", "lib");

		if (targetFlags.exists ("electron")) {

			dependencyPath = project.config.getString ("html5.dependency-path", dependencyPath);

		}

		outputFile = targetDirectory + "/bin/" + project.app.file + ".js";

	}


	public override function run ():Void {

		if (targetFlags.exists ("electron")) {

			ElectronHelper.launch (project, targetDirectory + "/bin");

		} else {

			HTML5Helper.launch (project, targetDirectory + "/bin");

		}

	}


	public override function update ():Void {

		AssetHelper.processLibraries (project, targetDirectory);

		// project = project.clone ();

		var destination = targetDirectory + "/bin/";
		System.mkdir (destination);

		var webfontDirectory = targetDirectory + "/obj/webfont";
		var useWebfonts = true;

		for (haxelib in project.haxelibs) {

			if (haxelib.name == "openfl-html5-dom" || haxelib.name == "openfl-bitfive") {

				useWebfonts = false;

			}

		}

		var fontPath;

		for (asset in project.assets) {

			if (asset.type == AssetType.FONT && asset.targetPath != null) {

				if (useWebfonts) {

					fontPath = Path.combine (webfontDirectory, Path.withoutDirectory (asset.targetPath));

					if (!FileSystem.exists (fontPath)) {

						System.mkdir (webfontDirectory);
						System.copyFile (asset.sourcePath, fontPath);

						var originalPath = asset.sourcePath;
						asset.sourcePath = fontPath;

						HTML5Helper.generateWebfonts (project, asset);

						var ext = "." + Path.extension (asset.sourcePath);
						var source = Path.withoutExtension (asset.sourcePath);
						var extensions = [ ext, ".eot", ".woff", ".svg" ];

						for (extension in extensions) {

							if (!FileSystem.exists (source + extension)) {

								if (extension != ".eot" && extension != ".svg") {

									Log.warn ("Could not generate *" + extension + " web font for \"" + originalPath + "\"");

								}

							}

						}

					}

					asset.sourcePath = fontPath;
					asset.targetPath = Path.withoutExtension (asset.targetPath);

				} else {

					// project.haxeflags.push (HTML5Helper.generateFontData (project, asset));

				}

			}

		}

		if (project.targetFlags.exists ("xml")) {

			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");

		}

		if (Log.verbose) {

			project.haxedefs.set ("verbose", 1);

		}

		ModuleHelper.updateProject (project);

		var libraryNames = new Map<String, Bool> ();

		for (asset in project.assets) {

			if (asset.library != null && !libraryNames.exists (asset.library)) {

				libraryNames[asset.library] = true;

			}

		}

		//for (library in libraryNames.keys ()) {
			//
			//project.haxeflags.push ("-resource " + targetDirectory + "/obj/manifest/" + library + ".json@__ASSET_MANIFEST__" + library);
			//
		//}

		//project.haxeflags.push ("-resource " + targetDirectory + "/obj/manifest/default.json@__ASSET_MANIFEST__default");

		var context = project.templateContext;

		context.WIN_FLASHBACKGROUND = project.window.background != null ? StringTools.hex (project.window.background, 6) : "";
		context.OUTPUT_DIR = targetDirectory;
		context.OUTPUT_FILE = outputFile;
		context.ELECTRON_MAIN = electronMain;

		if (project.targetFlags.exists ("webgl")) {

			context.CPP_DIR = targetDirectory + "/obj";

		}

		context.favicons = [];

		var icons = project.icons;

		if (icons.length == 0) {

			icons = [ new Icon (System.findTemplate (project.templatePaths, "default/icon.svg")) ];

		}

		//if (IconHelper.createWindowsIcon (icons, Path.combine (destination, "favicon.ico"))) {
			//
			//context.favicons.push ({ rel: "icon", type: "image/x-icon", href: "./favicon.ico" });
			//
		//}

		if (IconHelper.createIcon (icons, 192, 192, Path.combine (destination, "favicon.png"))) {

			context.favicons.push ({ rel: "shortcut icon", type: "image/png", href: "./favicon.png" });

		}

		context.linkedLibraries = [];

		for (dependency in project.dependencies) {

			if (StringTools.endsWith (dependency.name, ".js")) {

				context.linkedLibraries.push (dependency.name);

			} else if (StringTools.endsWith (dependency.path, ".js") && FileSystem.exists (dependency.path)) {

				var name = Path.withoutDirectory (dependency.path);

				context.linkedLibraries.push ("./" + dependencyPath + "/" + name);
				System.copyIfNewer (dependency.path, Path.combine (destination, Path.combine (dependencyPath, name)));

			}

		}

		for (asset in project.assets) {

			var path = Path.combine (destination, asset.targetPath);

			if (asset.type != AssetType.TEMPLATE) {

				if (/*asset.embed != true &&*/ asset.type != AssetType.FONT) {

					System.mkdir (Path.directory (path));
					AssetHelper.copyAssetIfNewer (asset, path);

				} else if (asset.type == AssetType.FONT && useWebfonts) {

					System.mkdir (Path.directory (path));
					var ext = "." + Path.extension (asset.sourcePath);
					var source = Path.withoutExtension (asset.sourcePath);

					var hasFormat = [ false, false, false, false ];
					var extensions = [ ext, ".eot", ".svg", ".woff" ];
					var extension;

					for (i in 0...extensions.length) {

						extension = extensions[i];

						if (FileSystem.exists (source + extension)) {

							System.copyIfNewer (source + extension, path + extension);
							hasFormat[i] = true;

						}

					}

					var shouldEmbedFont = false;

					for (embedded in hasFormat) {
						if (embedded) shouldEmbedFont = true;
					}

					var embeddedAssets:Array<Dynamic> = cast context.assets;
					for (embeddedAsset in embeddedAssets) {

						if (embeddedAsset.type == "font" && embeddedAsset.sourcePath == asset.sourcePath) {

							#if lime
							var font = Font.fromFile (asset.sourcePath);

							embeddedAsset.ascender = font.ascender;
							embeddedAsset.descender = font.descender;
							embeddedAsset.height = font.height;
							embeddedAsset.numGlyphs = font.numGlyphs;
							embeddedAsset.underlinePosition = font.underlinePosition;
							embeddedAsset.underlineThickness = font.underlineThickness;
							embeddedAsset.unitsPerEM = font.unitsPerEM;

							if (shouldEmbedFont) {

								var urls = [];
								if (hasFormat[1]) urls.push ("url('" + embeddedAsset.targetPath + ".eot?#iefix') format('embedded-opentype')");
								if (hasFormat[3]) urls.push ("url('" + embeddedAsset.targetPath + ".woff') format('woff')");
								urls.push ("url('" + embeddedAsset.targetPath + ext + "') format('truetype')");
								if (hasFormat[2]) urls.push ("url('" + embeddedAsset.targetPath + ".svg#" + StringTools.urlEncode (embeddedAsset.fontName) + "') format('svg')");

								var fontFace = "\t\t@font-face {\n";
								fontFace += "\t\t\tfont-family: '" + embeddedAsset.fontName + "';\n";
								// if (hasFormat[1]) fontFace += "\t\t\tsrc: url('" + embeddedAsset.targetPath + ".eot');\n";
								fontFace += "\t\t\tsrc: " + urls.join (",\n\t\t\t") + ";\n";
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

		ProjectHelper.recursiveSmartCopyTemplate (project, "html5/template", destination, context);

		if (project.app.main != null) {

			ProjectHelper.recursiveSmartCopyTemplate (project, "haxe", targetDirectory + "/haxe", context);
			ProjectHelper.recursiveSmartCopyTemplate (project, "html5/haxe", targetDirectory + "/haxe", context, true, false);
			ProjectHelper.recursiveSmartCopyTemplate (project, "html5/hxml", targetDirectory + "/haxe", context);

		}

		if (targetFlags.exists ("electron")) {

			ProjectHelper.recursiveSmartCopyTemplate (project, "electron/template", destination, context);

			if (project.app.main != null) {

				if (electronMain != ""){
					ProjectHelper.recursiveSmartCopyTemplate (project, electronMain + ".hx", targetDirectory + "/haxe/" + electronMain + ".hx", context, true, true, false);
				} else {
					ProjectHelper.recursiveSmartCopyTemplate (project, "electron/haxe", targetDirectory + "/haxe", context, true, false);
				}
				ProjectHelper.recursiveSmartCopyTemplate (project, "electron/hxml", targetDirectory + "/haxe", context);

			}

		}

		for (asset in project.assets) {

			var path = Path.combine (destination, asset.targetPath);

			if (asset.type == AssetType.TEMPLATE) {

				System.mkdir (Path.directory (path));
				AssetHelper.copyAsset (asset, path, context);

			}

		}

	}


	public override function watch ():Void {

		// TODO: Use a custom live reload HTTP server for test/run instead

		var dirs = []; // WatchHelper.processHXML (getDisplayHXML (), project.app.path);
		var command = ProjectHelper.getCurrentCommand ();
		System.watch (command, dirs);

	}


	@ignore public override function install ():Void {}
	@ignore public override function rebuild ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}


}
