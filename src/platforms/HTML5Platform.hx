package platforms;


import haxe.io.Path;
import haxe.Template;
import helpers.FileHelper;
import helpers.HTML5Helper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import project.AssetType;
import project.HXProject;
import sys.io.File;
import sys.FileSystem;


class HTML5Platform implements IPlatformTool {
	
	
	private var outputDirectory:String;
	private var outputFile:String;
	
	
	public function build (project:HXProject):Void {
		
		initialize (project);
		
		if (project.app.main != null) {
			
			var hxml = outputDirectory + "/haxe/" + (project.debug ? "debug" : "release") + ".hxml";
			ProcessHelper.runCommand ("", "haxe", [ hxml ] );
			
		}
		
		if (project.targetFlags.exists ("webgl")) {
			
			FileHelper.copyFile (outputDirectory + "/obj/ApplicationMain.js", outputFile);
			
		}
		
		if (project.targetFlags.exists ("minify")) {
			
			HTML5Helper.minify (project, outputDirectory + "/bin/" + project.app.file + ".js");
			
		}
		
	}
	
	
	public function clean (project:HXProject):Void {
		
		var targetPath = project.app.path + "/html5";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public function display (project:HXProject):Void {
		
		initialize (project);
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "html5/hxml/" + (project.debug ? "debug" : "release") + ".hxml");
		
		var context = project.templateContext;
		context.OUTPUT_DIR = outputDirectory;
		context.OUTPUT_FILE = outputFile;
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	private function initialize (project:HXProject):Void {
		
		outputDirectory = project.app.path + "/html5";
		outputFile = outputDirectory + "/bin/" + project.app.file + ".js";
		
	}
	
	
	public function run (project:HXProject, arguments:Array < String > ):Void {
		
		initialize (project);
		
		HTML5Helper.launch (project, project.app.path + "/html5/bin");
		
	}
	
	
	public function update (project:HXProject):Void {
		
		initialize (project);
		
		project = project.clone ();
		
		var destination = outputDirectory + "/bin/";
		PathHelper.mkdir (destination);
		
		for (asset in project.assets) {
			
			if (asset.type == AssetType.FONT) {
				
				project.haxeflags.push (HTML5Helper.generateFontData (project, asset));
				
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
		
		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination, asset.targetPath);
			
			if (asset.type != AssetType.TEMPLATE) {
				
				if (asset.type != AssetType.FONT) {
					
					PathHelper.mkdir (Path.directory (path));
					FileHelper.copyAssetIfNewer (asset, path);
					
				}
				
			}
			
		}
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/template", destination, context);
		
		if (project.app.main != null) {
			
			FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", outputDirectory + "/haxe", context);
			
			if (!project.targetFlags.exists ("webgl")) {
				
				FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/haxe", outputDirectory + "/haxe", context);
				FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/hxml", outputDirectory + "/haxe", context);
				
			} else {
				
				FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/haxe", outputDirectory + "/haxe", context);
				FileHelper.recursiveCopyTemplate (project.templatePaths, "webgl/hxml", outputDirectory + "/haxe", context);
				
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
	
	
	public function new () {}
	@ignore public function install (project:HXProject):Void {}
	@ignore public function trace (project:HXProject):Void {}
	@ignore public function uninstall (project:HXProject):Void {}
	
	
}