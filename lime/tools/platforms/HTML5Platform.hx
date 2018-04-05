package lime.tools.platforms;


import haxe.io.Path;
import haxe.Template;
import lime.text.Font;
import lime.tools.helpers.DeploymentHelper;
import lime.tools.helpers.FileHelper;
import lime.tools.helpers.HTML5Helper;
import lime.tools.helpers.IconHelper;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.ModuleHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.ProcessHelper;
import lime.tools.helpers.WatchHelper;
import lime.project.AssetType;
import lime.project.HXProject;
import lime.project.Icon;
import lime.project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


class HTML5Platform extends PlatformTarget {
	
	
	private var dependencyPath:String;
	private var outputFile:String;
	
	
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
			ProcessHelper.runCommand ("", "haxe", [ hxml ] );
			
			if (noOutput) return;
			
			HTML5Helper.encodeSourceMappingURL (targetDirectory + "/bin/" + project.app.file + ".js"); 
			
			if (project.targetFlags.exists ("webgl")) {
				
				FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain.js", outputFile);
				
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
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public override function deploy ():Void {
		
		DeploymentHelper.deploy (project, targetFlags, targetDirectory, "HTML5");
		
	}
	
	
	public override function display ():Void {
		
		Sys.println (getDisplayHXML ());
		
	}
	
	
	private function getDisplayHXML ():String {
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "html5/hxml/" + buildType + ".hxml");
		
		var context = project.templateContext;
		context.OUTPUT_DIR = targetDirectory;
		context.OUTPUT_FILE = outputFile;
		
		var template = new Template (File.getContent (hxml));
		
		return template.execute (context) + "\n-D display";
		
	}
	
	
	private function initialize (command:String, project:HXProject):Void {
		
		targetDirectory = PathHelper.combine (project.app.path, project.config.getString ("html5.output-directory", "html5"));
		dependencyPath = project.config.getString ("html5.dependency-path", "lib");
		outputFile = targetDirectory + "/bin/" + project.app.file + ".js";
		
	}
	
	
	public override function run ():Void {
		
		HTML5Helper.launch (project, targetDirectory + "/bin");
		
	}
	
	
	public override function update ():Void {
		
		project = project.clone ();
		
		var destination = targetDirectory + "/bin/";
		PathHelper.mkdir (destination);
		
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
					
					fontPath = PathHelper.combine (webfontDirectory, Path.withoutDirectory (asset.targetPath));
					
					if (!FileSystem.exists (fontPath)) {
						
						PathHelper.mkdir (webfontDirectory);
						FileHelper.copyFile (asset.sourcePath, fontPath);
						
						var originalPath = asset.sourcePath;
						asset.sourcePath = fontPath;
						
						HTML5Helper.generateWebfonts (project, asset);
						
						var ext = "." + Path.extension (asset.sourcePath);
						var source = Path.withoutExtension (asset.sourcePath);
						var extensions = [ ext, ".eot", ".woff", ".svg" ];
						
						for (extension in extensions) {
							
							if (!FileSystem.exists (source + extension)) {
								
								if (extension != ".eot" && extension != ".svg") {
									
									LogHelper.warn ("Could not generate *" + extension + " web font for \"" + originalPath + "\"");
									
								}
								
							}
							
						}
						
					}
					
					asset.sourcePath = fontPath;
					asset.targetPath = Path.withoutExtension (asset.targetPath);
					
				} else {
					
					project.haxeflags.push (HTML5Helper.generateFontData (project, asset));
					
				}
				
			}
			
		}
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		if (LogHelper.verbose) {
			
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
		
		if (project.targetFlags.exists ("webgl")) {
			
			context.CPP_DIR = targetDirectory + "/obj";
			
		}
		
		context.favicons = [];
		
		var icons = project.icons;
		
		if (icons.length == 0) {
			
			icons = [ new Icon (PathHelper.findTemplate (project.templatePaths, "default/icon.svg")) ];
			
		}
		
		//if (IconHelper.createWindowsIcon (icons, PathHelper.combine (destination, "favicon.ico"))) {
			//
			//context.favicons.push ({ rel: "icon", type: "image/x-icon", href: "./favicon.ico" });
			//
		//}
		
		if (IconHelper.createIcon (icons, 192, 192, PathHelper.combine (destination, "favicon.png"))) {
			
			context.favicons.push ({ rel: "shortcut icon", type: "image/png", href: "./favicon.png" });
			
		}
		
		context.linkedLibraries = [];
		
		for (dependency in project.dependencies) {
			
			if (StringTools.endsWith (dependency.name, ".js")) {
				
				context.linkedLibraries.push (dependency.name);
				
			} else if (StringTools.endsWith (dependency.path, ".js") && FileSystem.exists (dependency.path)) {
				
				var name = Path.withoutDirectory (dependency.path);
				
				context.linkedLibraries.push ("./" + dependencyPath + "/" + name);
				FileHelper.copyIfNewer (dependency.path, PathHelper.combine (destination, PathHelper.combine (dependencyPath, name)));
				
			}
			
		}
		
		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination, asset.targetPath);
			
			if (asset.type != AssetType.TEMPLATE) {
				
				if (asset.embed != true && asset.type != AssetType.FONT) {
					
					PathHelper.mkdir (Path.directory (path));
					FileHelper.copyAssetIfNewer (asset, path);
					
				} else if (asset.type == AssetType.FONT && useWebfonts) {
					
					PathHelper.mkdir (Path.directory (path));
					var ext = "." + Path.extension (asset.sourcePath);
					var source = Path.withoutExtension (asset.sourcePath);
					
					var hasFormat = [ false, false, false, false ];
					var extensions = [ ext, ".eot", ".svg", ".woff" ];
					var extension;
					
					for (i in 0...extensions.length) {
						
						extension = extensions[i];
						
						if (FileSystem.exists (source + extension)) {
							
							FileHelper.copyIfNewer (source + extension, path + extension);
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
							
						}
						
					}
					
				}
				
			}
			
		}
		
		FileHelper.recursiveSmartCopyTemplate (project, "html5/template", destination, context);
		
		if (project.app.main != null) {
			
			FileHelper.recursiveSmartCopyTemplate (project, "haxe", targetDirectory + "/haxe", context);
			FileHelper.recursiveSmartCopyTemplate (project, "html5/haxe", targetDirectory + "/haxe", context, true, false);
			FileHelper.recursiveSmartCopyTemplate (project, "html5/hxml", targetDirectory + "/haxe", context);
			
			if (project.targetFlags.exists ("webgl")) {
				
				FileHelper.recursiveSmartCopyTemplate (project, "webgl/hxml", targetDirectory + "/haxe", context, true, false);
				
			}
			
		}
		
		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination, asset.targetPath);
			
			if (asset.type == AssetType.TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (path));
				FileHelper.copyAsset (asset, path, context);
				
			}
			
		}
		
	}
	
	
	public override function watch ():Void {
		
		// TODO: Use a custom live reload HTTP server for test/run instead
		
		var dirs = WatchHelper.processHXML (project, getDisplayHXML ());
		var command = WatchHelper.getCurrentCommand ();
		WatchHelper.watch (project, command, dirs);
		
	}
	
	
	@ignore public override function install ():Void {}
	@ignore public override function rebuild ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}