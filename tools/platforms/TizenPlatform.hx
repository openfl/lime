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
		
		targetDirectory = project.app.path + "/tizen";
		
	}
	
	
	public override function build ():Void {
		
		var destination = targetDirectory + "/bin/";
		
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
		
		var hxml = targetDirectory + "/haxe/" + type + ".hxml";
		
		ProcessHelper.runCommand ("", "haxe", [ hxml, "-D", "tizen" ] );
		
		var args = [ "-Dtizen", "-DAPP_ID=" + TizenHelper.getUUID (project) ];
		
		if (project.targetFlags.exists ("simulator")) {
			
			args.push ("-Dsimulator");
			
		}
		
		CPPHelper.compile (project, targetDirectory + "/obj", args);
		FileHelper.copyIfNewer (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", targetDirectory + "/bin/CommandLineBuild/" + project.app.file + ".exe");
		TizenHelper.createPackage (project, targetDirectory + "/bin/CommandLineBuild", "");
		
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
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "tizen/hxml/" + type + ".hxml");
		
		var context = project.templateContext;
		context.CPP_DIR = targetDirectory + "/obj";
		
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
		
		TizenHelper.install (project, targetDirectory + "/bin/CommandLineBuild");
		TizenHelper.launch (project);
		
	}
	
	
	public override function trace ():Void {
		
		TizenHelper.trace (project);
		
	}
	
	
	public override function update ():Void {
		
		project = project.clone ();
		var destination = targetDirectory + "/bin/";
		PathHelper.mkdir (destination);
		
		for (asset in project.assets) {
			
			asset.resourceName = "../res/" + asset.resourceName;
			
		}
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		var context = project.templateContext;
		context.CPP_DIR = targetDirectory + "/obj";
		context.APP_PACKAGE = TizenHelper.getUUID (project);
		context.SIMULATOR = project.targetFlags.exists ("simulator");
		
		PathHelper.mkdir (destination + "shared/res/screen-density-xhigh");
		
		if (IconHelper.createIcon (project.icons, 117, 117, PathHelper.combine (destination + "shared/res/screen-density-xhigh", "mainmenu.png"))) {
			
			context.APP_ICON = "mainmenu.png";
			
		}
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "tizen/template", destination, context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "tizen/hxml", targetDirectory + "/haxe", context);
		
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