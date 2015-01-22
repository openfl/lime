package platforms;


import haxe.io.Path;
import haxe.Template;
import helpers.AssetHelper;
import helpers.FileHelper;
import helpers.HTML5Helper;
import helpers.LogHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import project.AssetType;
import project.HXProject;
import project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


class HTML5Platform extends PlatformTarget {
	
	
	private var outputFile:String;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map <String, String> ) {
		
		initialize (command, _project);
		
		super (command, _project, targetFlags);
		
	}
	
	
	public override function build ():Void {
		
		if (project.app.main != null) {
			
			var type = "release";
			
			if (project.debug) {
				
				type = "debug";
				
			} else if (project.targetFlags.exists ("final")) {
				
				type = "final";
				
			}
			
			var hxml = targetDirectory + "/haxe/" + type + ".hxml";
			ProcessHelper.runCommand ("", "haxe", [ hxml ] );
			
			if (project.targetFlags.exists ("webgl")) {
				
				FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain.js", outputFile);
				
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
	
	
	public override function display ():Void {
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "html5/hxml/" + type + ".hxml");
		
		var context = project.templateContext;
		context.OUTPUT_DIR = targetDirectory;
		context.OUTPUT_FILE = outputFile;
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	private function initialize (command:String, project:HXProject):Void {
	
		targetDirectory = project.app.path + "/html5";
		outputFile = targetDirectory + "/bin/" + project.app.file + ".js";

	}
	
	
	public override function run ():Void {
		
		HTML5Helper.launch (project, targetDirectory + "/bin");
		
	}
	
	
	public override function update ():Void {
		
		project = project.clone ();
		
		var destination = targetDirectory + "/bin/";
		PathHelper.mkdir (destination);
		
		var useWebfonts = true;
		
		for (haxelib in project.haxelibs) {
			
			if (haxelib.name == "openfl-html5-dom" || haxelib.name == "openfl-bitfive") {
				
				useWebfonts = false;
				
			}
			
		}
		
		for (asset in project.assets) {
			
			if (asset.type == AssetType.FONT) {
				
				if (useWebfonts) {
					
					HTML5Helper.generateWebfonts (project, asset);
					asset.targetPath = Path.withoutExtension (asset.targetPath);
					
				} else {
					
					project.haxeflags.push (HTML5Helper.generateFontData (project, asset));
					
				}
				
			}
			
		}
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		var context = project.templateContext;
		
		context.WIN_FLASHBACKGROUND = StringTools.hex (project.window.background, 6);
		context.OUTPUT_DIR = targetDirectory;
		context.OUTPUT_FILE = outputFile;
		
		if (project.targetFlags.exists ("webgl")) {
			
			context.CPP_DIR = targetDirectory + "/obj";
			
		}
		
		context.linkedLibraries = [];
		
		for (dependency in project.dependencies) {
			
			if (StringTools.endsWith (dependency.name, ".js")) {
				
				context.linkedLibraries.push (dependency.name);
				
			} else if (StringTools.endsWith (dependency.path, ".js") && FileSystem.exists (dependency.path)) {
				
				var name = Path.withoutDirectory (dependency.path);
				
				context.linkedLibraries.push ("./lib/" + name);
				FileHelper.copyIfNewer (dependency.path, PathHelper.combine (destination, PathHelper.combine ("lib", name)));
				
			}
			
		}
		
		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination, asset.targetPath);
			
			if (asset.type != AssetType.TEMPLATE) {
				
				if (asset.type != AssetType.FONT) {
					
					PathHelper.mkdir (Path.directory (path));
					FileHelper.copyAssetIfNewer (asset, path);
					
				} else if (useWebfonts) {
					
					PathHelper.mkdir (Path.directory (path));
					var ext = "." + Path.extension (asset.sourcePath);
					var source = Path.withoutExtension (asset.sourcePath);
					
					for (extension in [ ext, ".eot", ".woff", ".svg" ]) {
						
						if (FileSystem.exists (source + extension)) {
							
							FileHelper.copyIfNewer (source + extension, path + extension);
							
						} else {
							
							LogHelper.warn ("Could not find generated font file \"" + source + extension + "\"");
							
						}
						
					}
					
				}
				
			}
			
		}
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/template", destination, context);
		
		if (project.app.main != null) {
			
			FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/haxe", targetDirectory + "/haxe", context, true, false);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/hxml", targetDirectory + "/haxe", context);
				
			if (project.targetFlags.exists ("webgl")) {
				
				FileHelper.recursiveCopyTemplate (project.templatePaths, "webgl/hxml", targetDirectory + "/haxe", context, true, false);
				
			}
			
		}
		
		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination, asset.targetPath);
			
			if (asset.type == AssetType.TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (path));
				FileHelper.copyAsset (asset, path, context);
				
			}
			
		}
		
		AssetHelper.createManifest (project, PathHelper.combine (destination, "manifest"));
		
	}
	
	
	@ignore public override function install ():Void {}
	@ignore public override function rebuild ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}