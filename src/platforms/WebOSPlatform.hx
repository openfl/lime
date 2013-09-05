package platforms;


import haxe.io.Path;
import haxe.Template;
import helpers.AssetHelper;
import helpers.FileHelper;
import helpers.IconHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import helpers.WebOSHelper;
import openfl.Assets;
import project.OpenFLProject;
import sys.io.File;
import sys.FileSystem;


class WebOSPlatform implements IPlatformTool {
	
	
	public function build (project:OpenFLProject):Void {
		
		var hxml = project.app.path + "/webos/haxe/" + (project.debug ? "debug" : "release") + ".hxml";
		ProcessHelper.runCommand ("", "haxe", [ hxml ] );
		
		FileHelper.copyIfNewer (project.app.path + "/webos/obj/ApplicationMain" + (project.debug ? "-debug" : ""), project.app.path + "/webos/bin/" + project.app.file);
		
		WebOSHelper.createPackage (project, project.app.path + "/webos", "bin");
		
	}
	
	
	public function clean (project:OpenFLProject):Void {
		
		var targetPath = project.app.path + "/webos";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public function display (project:OpenFLProject):Void {
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "webos/hxml/" + (project.debug ? "debug" : "release") + ".hxml");
		
		var context = project.templateContext;
		context.CPP_DIR = project.app.path + "/webos/obj";
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	public function run (project:OpenFLProject, arguments:Array <String>):Void {
		
		WebOSHelper.install (project, project.app.path + "/webos");
		WebOSHelper.launch (project);
		
	}
	
	
	public function trace (project:OpenFLProject):Void {
		
		WebOSHelper.trace (project);
		
	}
	
	
	public function update (project:OpenFLProject):Void {
		
		project = project.clone ();
		var destination = project.app.path + "/webos/bin/";
		PathHelper.mkdir (destination);
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + project.app.path + "/webos/types.xml");
			
		}
		
		var context = project.templateContext;
		context.CPP_DIR = project.app.path + "/webos/obj";
		
		if (IconHelper.createIcon (project.icons, 64, 64, PathHelper.combine (destination, "icon.png"))) {
			
			context.APP_ICON = "icon.png";
			
		}
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "webos/template", destination, context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", project.app.path + "/webos/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "webos/hxml", project.app.path + "/webos/haxe", context);
		
		//SWFHelper.generateSWFClasses (project, project.app.path + "/webos/haxe");
		
		for (ndll in project.ndlls) {
			
			FileHelper.copyLibrary (ndll, "webOS", "", ".so", destination, project.debug);
			
		}
		
		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination, asset.targetPath);
			
			PathHelper.mkdir (Path.directory (path));
			
			if (asset.type != AssetType.TEMPLATE) {
				
				if (asset.targetPath == "/appinfo.json") {
					
					FileHelper.copyAsset (asset, path, context);
					
				} else {
					
					// going to root directory now, but should it be a forced "assets" folder later?
					
					FileHelper.copyAssetIfNewer (asset, path);
					
				}
				
			} else {
				
				FileHelper.copyAsset (asset, path, context);
				
			}
			
		}
		
		AssetsHelper.createManifest (project, PathHelper.combine (destination, "manifest"));
		
	}
	
	
	public function new () {}
	@ignore public function install (project:OpenFLProject):Void {}
	@ignore public function uninstall (project:OpenFLProject):Void {}
	
	
}