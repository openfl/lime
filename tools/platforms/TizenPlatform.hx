package;


import haxe.io.Path;
import haxe.Template;
import hxp.helpers.CPPHelper;
import hxp.helpers.DeploymentHelper;
import hxp.helpers.FileHelper;
import hxp.helpers.IconHelper;
import hxp.helpers.PathHelper;
import hxp.helpers.ProcessHelper;
import hxp.helpers.TizenHelper;
import hxp.project.AssetType;
import hxp.project.HXProject;
import hxp.project.Icon;
import hxp.project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


class TizenPlatform extends PlatformTarget {
	
	
	private static var uuid:String = null;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map<String, String> ) {
		
		super (command, _project, targetFlags);
		
		targetDirectory = PathHelper.combine (project.app.path, project.config.getString ("tizen.output-directory", "tizen"));
		
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
		
		var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";
		
		ProcessHelper.runCommand ("", "haxe", [ hxml, "-D", "tizen" ] );
		
		if (noOutput) return;
		
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
	
	
	public override function deploy ():Void {
		
		DeploymentHelper.deploy (project, targetFlags, targetDirectory, "Tizen");
		
	}
	
	
	public override function display ():Void {
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "tizen/hxml/" + buildType + ".hxml");
		
		var context = project.templateContext;
		context.CPP_DIR = targetDirectory + "/obj";
		context.OUTPUT_DIR = targetDirectory;
		
		var template = new Template (File.getContent (hxml));
		
		Sys.println (template.execute (context));
		Sys.println ("-D display");
		
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
		
		// project = project.clone ();
		
		for (asset in project.assets) {
			
			if (asset.embed && asset.sourcePath == "") {
				
				var path = PathHelper.combine (targetDirectory + "/obj/tmp", asset.targetPath);
				PathHelper.mkdir (Path.directory (path));
				FileHelper.copyAsset (asset, path);
				asset.sourcePath = path;
				
			}
			
		}
		
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
		context.OUTPUT_DIR = targetDirectory;
		context.APP_PACKAGE = TizenHelper.getUUID (project);
		context.SIMULATOR = project.targetFlags.exists ("simulator");
		
		PathHelper.mkdir (destination + "shared/res/screen-density-xhigh");
		
		var icons = project.icons;
		
		if (icons.length == 0) {
			
			icons = [ new Icon (PathHelper.findTemplate (project.templatePaths, "default/icon.svg")) ];
			
		}
		
		if (IconHelper.createIcon (icons, 117, 117, PathHelper.combine (destination + "shared/res/screen-density-xhigh", "mainmenu.png"))) {
			
			context.APP_ICON = "mainmenu.png";
			
		}
		
		FileHelper.recursiveSmartCopyTemplate (project, "tizen/template", destination, context);
		FileHelper.recursiveSmartCopyTemplate (project, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveSmartCopyTemplate (project, "tizen/hxml", targetDirectory + "/haxe", context);
		
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
		
	}
	
	
	@ignore public override function install ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}