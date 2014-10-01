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
	
	
	private var outputDirectory:String;
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
			
			var hxml = outputDirectory + "/haxe/" + type + ".hxml";
			ProcessHelper.runCommand ("", "haxe", [ hxml ] );
			
		}
		
		if (project.targetFlags.exists ("webgl")) {
			
			FileHelper.copyFile (outputDirectory + "/obj/ApplicationMain.js", outputFile);
			
		}
		
		if (project.targetFlags.exists ("minify")) {
			
			HTML5Helper.minify (project, outputDirectory + "/bin/" + project.app.file + ".js");
			
		}
		
	}
	
	
	public override function clean ():Void {
		
		var targetPath = project.app.path + "/html5";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
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
		context.OUTPUT_DIR = outputDirectory;
		context.OUTPUT_FILE = outputFile;
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	private function initialize (command:String, project:HXProject):Void {
	
		outputDirectory = project.app.path + "/html5";
		outputFile = outputDirectory + "/bin/" + project.app.file + ".js";

	}
	
	
	public override function run ():Void {
		
		HTML5Helper.launch (project, project.app.path + "/html5/bin");
		
	}
	
	
	public override function update ():Void {
		
		project = project.clone ();
		
		var destination = outputDirectory + "/bin/";
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
			
			project.haxeflags.push ("-xml " + project.app.path + "/html5/types.xml");
			
		}
		
		var context = project.templateContext;
		
		context.WIN_FLASHBACKGROUND = StringTools.hex (project.window.background, 6);
		context.OUTPUT_DIR = outputDirectory;
		context.OUTPUT_FILE = outputFile;
		
		if (project.targetFlags.exists ("webgl")) {
			
			context.CPP_DIR = project.app.path + "/html5/obj";
			
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
			
			FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", outputDirectory + "/haxe", context);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/haxe", outputDirectory + "/haxe", context, true, false);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/hxml", outputDirectory + "/haxe", context);
				
			if (project.targetFlags.exists ("webgl")) {
				
				FileHelper.recursiveCopyTemplate (project.templatePaths, "webgl/hxml", outputDirectory + "/haxe", context, true, false);
				
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