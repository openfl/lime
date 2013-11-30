package platforms;


import haxe.io.Path;
import haxe.Template;
import helpers.AssetHelper;
import helpers.CPPHelper;
import helpers.FileHelper;
import helpers.IconHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import helpers.TizenHelper;
import project.AssetType;
import project.HXProject;
import sys.io.File;
import sys.FileSystem;


class TizenPlatform implements IPlatformTool {
	
	
	private static var uuid:String = null;
	
	
	public function build (project:HXProject):Void {
		
		var hxml = project.app.path + "/tizen/haxe/" + (project.debug ? "debug" : "release") + ".hxml";
		
		ProcessHelper.runCommand ("", "haxe", [ hxml, "-D", "tizen" ] );
		CPPHelper.compile (project, project.app.path + "/tizen/obj", [ "-Dtizen", "-DAPP_ID=" + TizenHelper.getUUID (project) ]);
		
		FileHelper.copyIfNewer (project.app.path + "/tizen/obj/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", project.app.path + "/tizen/bin/CommandLineBuild/" + project.app.file + ".exe");
		
		TizenHelper.createPackage (project, project.app.path + "/tizen/bin/CommandLineBuild", "");
		
	}
	
	
	public function clean (project:HXProject):Void {
		
		var targetPath = project.app.path + "/tizen";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public function display (project:HXProject):Void {
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "tizen/hxml/" + (project.debug ? "debug" : "release") + ".hxml");
		
		var context = project.templateContext;
		context.CPP_DIR = project.app.path + "/tizen/obj";
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	public function run (project:HXProject, arguments:Array <String>):Void {
		
		TizenHelper.install (project, project.app.path + "/tizen/bin/CommandLineBuild");
		TizenHelper.launch (project);
		
	}
	
	
	public function trace (project:HXProject):Void {
		
		TizenHelper.trace (project);
		
	}
	
	
	public function update (project:HXProject):Void {
		
		project = project.clone ();
		var destination = project.app.path + "/tizen/bin/";
		PathHelper.mkdir (destination);
		
		for (asset in project.assets) {
			
			asset.resourceName = "../res/" + asset.resourceName;
			
		}
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + project.app.path + "/tizen/types.xml");
			
		}
		
		var context = project.templateContext;
		context.CPP_DIR = project.app.path + "/tizen/obj";
		context.APP_PACKAGE = TizenHelper.getUUID (project);
		
		PathHelper.mkdir (destination + "shared/res/screen-density-xhigh");
		
		if (IconHelper.createIcon (project.icons, 117, 117, PathHelper.combine (destination + "shared/res/screen-density-xhigh", "mainmenu.png"))) {
			
			context.APP_ICON = "mainmenu.png";
			
		}
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "tizen/template", destination, context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", project.app.path + "/tizen/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "tizen/hxml", project.app.path + "/tizen/haxe", context);
		
		//SWFHelper.generateSWFClasses (project, project.app.path + "/tizen/haxe");
		
		for (ndll in project.ndlls) {
			
			FileHelper.copyLibrary (ndll, "Tizen", "", ".so", destination + "lib/", project.debug);
			
		}
		
		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination + "res/", asset.targetPath);
			
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
		
		AssetHelper.createManifest (project, PathHelper.combine (destination + "res/", "manifest"));
		
	}
	
	
	public function new () {}
	@ignore public function install (project:HXProject):Void {}
	@ignore public function uninstall (project:HXProject):Void {}
	
	
}