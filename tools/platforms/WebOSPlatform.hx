package platforms;


import haxe.io.Path;
import haxe.Template;
import helpers.AssetHelper;
import helpers.CPPHelper;
import helpers.FileHelper;
import helpers.IconHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import helpers.WebOSHelper;
import project.AssetType;
import project.HXProject;
import project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


class WebOSPlatform extends PlatformTarget {
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map <String, String> ) {
		
		super (command, _project, targetFlags);
		
		targetDirectory = project.app.path + "/webos";
		
	}
	
	
	public override function build ():Void {
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = targetDirectory + "/haxe/" + type + ".hxml";
		var destination = targetDirectory + "/bin/";
		
		for (ndll in project.ndlls) {
			
			FileHelper.copyLibrary (project, ndll, "webOS", "", ".so", destination, project.debug);
			
		}
		
		ProcessHelper.runCommand ("", "haxe", [ hxml, "-D", "webos", "-D", "HXCPP_LOAD_DEBUG", "-D", "HXCPP_RTLD_LAZY" ] );
		CPPHelper.compile (project, targetDirectory + "/obj", [ "-Dwebos", "-DHXCPP_LOAD_DEBUG", "-DHXCPP_RTLD_LAZY" ]);
		
		FileHelper.copyIfNewer (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), targetDirectory + "/bin/" + project.app.file);
		
		WebOSHelper.createPackage (project, targetDirectory + "", "bin");
		
	}
	
	
	public override function clean ():Void {
		
		var targetPath = targetDirectory + "";
		
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
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "webos/hxml/" + type + ".hxml");
		
		var context = project.templateContext;
		context.CPP_DIR = targetDirectory + "/obj";
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	public override function install ():Void {
		
		WebOSHelper.install (project, targetDirectory + "");
		
	}
	
	
	public override function rebuild ():Void {
		
		CPPHelper.rebuild (project, [[ "-Dwebos" ]]);
		
	}
	
	
	public override function run ():Void {
		
		WebOSHelper.launch (project);
		
	}
	
	
	public override function trace ():Void {
		
		WebOSHelper.trace (project);
		
	}
	
	
	public override function update ():Void {
		
		project = project.clone ();
		var destination = targetDirectory + "/bin/";
		PathHelper.mkdir (destination);
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		var context = project.templateContext;
		context.CPP_DIR = targetDirectory + "/obj";
		
		if (IconHelper.createIcon (project.icons, 64, 64, PathHelper.combine (destination, "icon.png"))) {
			
			context.APP_ICON = "icon.png";
			
		}
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "webos/template", destination, context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "webos/hxml", targetDirectory + "/haxe", context);
		
		//SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");
		
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
		
		AssetHelper.createManifest (project, PathHelper.combine (destination, "manifest"));
		
	}
	
	
	@ignore public override function uninstall ():Void {}
	
	
}