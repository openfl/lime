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
import project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


class TizenPlatform extends PlatformTarget {
	
	
	private static var uuid:String = null;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map <String, String> ) {
		
		super (command, _project, targetFlags);
		
	}
	
	
	public override function build ():Void {
		
		var destination = project.app.path + "/tizen/bin/";
		
		var arch = "";
		
		if (project.targetFlags.exists ("simulator")) {
			
			arch = "-x86";
			
		}
		
		for (ndll in project.ndlls) {
			
			FileHelper.copyLibrary (project, ndll, "Tizen", "", arch + ".so", destination + "lib/", project.debug, ".so");
			
		}
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = project.app.path + "/tizen/haxe/" + type + ".hxml";
		
		ProcessHelper.runCommand ("", "haxe", [ hxml, "-D", "tizen" ] );
		
		var args = [ "-Dtizen", "-DAPP_ID=" + TizenHelper.getUUID (project) ];
		
		if (project.targetFlags.exists ("simulator")) {
			
			args.push ("-Dsimulator");
			
		}
		
		CPPHelper.compile (project, project.app.path + "/tizen/obj", args);
		FileHelper.copyIfNewer (project.app.path + "/tizen/obj/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", project.app.path + "/tizen/bin/CommandLineBuild/" + project.app.file + ".exe");
		TizenHelper.createPackage (project, project.app.path + "/tizen/bin/CommandLineBuild", "");
		
	}
	
	
	public override function clean ():Void {
		
		var targetPath = project.app.path + "/tizen";
		
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
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "tizen/hxml/" + type + ".hxml");
		
		var context = project.templateContext;
		context.CPP_DIR = project.app.path + "/tizen/obj";
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	public override function rebuild ():Void {
		
		var device = (command == "rebuild" || !targetFlags.exists ("simulator"));
		var simulator = (command == "rebuild" || targetFlags.exists ("simulator"));
		
		var commands = [];
		
		if (device) commands.push ([ "-Dtizen" ]);
		if (simulator) commands.push ([ "-Dtizen", "-Dsimulator" ]);
		
		CPPHelper.rebuild (project, commands);
		
	}
	
	
	public override function run ():Void {
		
		TizenHelper.install (project, project.app.path + "/tizen/bin/CommandLineBuild");
		TizenHelper.launch (project);
		
	}
	
	
	public override function trace ():Void {
		
		TizenHelper.trace (project);
		
	}
	
	
	public override function update ():Void {
		
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
		context.SIMULATOR = project.targetFlags.exists ("simulator");
		
		PathHelper.mkdir (destination + "shared/res/screen-density-xhigh");
		
		if (IconHelper.createIcon (project.icons, 117, 117, PathHelper.combine (destination + "shared/res/screen-density-xhigh", "mainmenu.png"))) {
			
			context.APP_ICON = "mainmenu.png";
			
		}
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "tizen/template", destination, context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", project.app.path + "/tizen/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "tizen/hxml", project.app.path + "/tizen/haxe", context);
		
		//SWFHelper.generateSWFClasses (project, project.app.path + "/tizen/haxe");
		
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
	
	
	@ignore public override function install ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}