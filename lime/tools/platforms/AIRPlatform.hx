package lime.tools.platforms;


import haxe.io.Path;
import lime.project.AssetType;
import lime.project.HXProject;
import lime.project.Icon;
import lime.project.Platform;
import lime.project.PlatformType;
import lime.tools.helpers.AIRHelper;
import lime.tools.helpers.DeploymentHelper;
import lime.tools.helpers.FileHelper;
import lime.tools.helpers.FlashHelper;
import lime.tools.helpers.IconHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.LogHelper;
import sys.io.File;
import sys.FileSystem;


class AIRPlatform extends FlashPlatform {
	
	
	private var iconData:Array<Dynamic>;
	private var targetPlatform:Platform;
	private var targetPlatformType:PlatformType;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map<String, String>) {
		
		super (command, _project, targetFlags);
		
		targetDirectory = PathHelper.combine (project.app.path, project.config.getString ("air.output-directory", "air"));
		targetPlatform = PlatformHelper.hostPlatform;
		targetPlatformType = DESKTOP;
		
	}
	
	
	public override function build ():Void {
		
		super.build ();
		
		if (!project.defines.exists ("AIR_SDK")) {
			
			LogHelper.error ("You must define AIR_SDK with the path to your AIR SDK");
			
		}
		
		// TODO: Should we package on desktop in "deploy" command instead?
		
		if (targetPlatformType != DESKTOP) {
			
			var files = [ project.app.file + ".swf" ];
			for (asset in project.assets) {
				
				if (asset.embed == false && asset.type != TEMPLATE) {
					
					files.push (asset.targetPath);
					
				}
				
			}
			
			for (icon in iconData) {
				
				files.push (icon.path);
				
			}
			
			AIRHelper.build (project, targetDirectory, targetPlatform, "bin/" + project.app.file + ".air", "application.xml", files, "bin");
			
		}
		
	}
	
	
	public override function clean ():Void {
		
		if (FileSystem.exists (targetDirectory)) {
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public override function deploy ():Void {
		
		if (targetFlags.exists ("gdrive") || targetFlags.exists ("zip")) {
			
			DeploymentHelper.deploy (project, targetFlags, targetDirectory, "AIR");
			
		} else {
			
			var name = project.meta.title + " (" + project.meta.version + " build " + project.meta.buildNumber + ").air";
			
			var rootDirectory = targetDirectory + "/bin";
			var paths = PathHelper.readDirectory (rootDirectory);
			var files = [];
			
			for (path in paths) {
				
				files.push (path.substr (rootDirectory.length + 1));
				
			}
			
			AIRHelper.build (project, targetDirectory, targetPlatform, name, "application.xml", files, "bin");
			
		}
		
	}
	
	
	public override function run ():Void {
		
		AIRHelper.run (project, targetDirectory, targetPlatform, "application.xml", "bin");
		
	}
	
	
	public override function update ():Void {
		
		var destination = targetDirectory + "/bin/";
		PathHelper.mkdir (destination);
		
		project = project.clone ();
		
		embedded = FlashHelper.embedAssets (project, targetDirectory);
		
		var context = generateContext ();
		context.OUTPUT_DIR = targetDirectory;
		
		var iconSizes = [ 16, 32, 48, 128 ];
		var icons = project.icons;
		iconData = [];
		
		if (icons.length == 0) {
			
			icons = [ new Icon (PathHelper.findTemplate (project.templatePaths, "default/icon.svg")) ];
			
		}
		
		for (size in iconSizes) {
			
			if (IconHelper.createIcon (icons, size, size, targetDirectory + "/bin/_res/icon-" + size + ".png")) {
				
				iconData.push ({ size: size, path: "_res/icon-" + size + ".png" });
				
			}
			
		}
		
		if (iconData.length > 0) context.icons = iconData;
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "air/hxml", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "air/template", targetDirectory, context);
		
		if (embedded) {
			
			var files = [ "debug.hxml", "release.hxml", "final.hxml" ];
			var path, hxml, lines, output;
			
			for (file in files) {
				
				path = targetDirectory + "/haxe/" + file;
				hxml = File.getContent (path);
				
				if (hxml.indexOf ("-swf-header") > -1) {
					
					lines = ~/[\r\n]+/g.split (hxml);
					output = [];
					
					for (line in lines) {
						
						if (line.indexOf ("-swf-header") > -1) continue;
						output.push (line);
						
					}
					
					if (output.length < lines.length) {
						
						File.saveContent (path, output.join ("\n"));
						
					}
					
				}
				
			}
			
		}
		
		for (asset in project.assets) {
			
			if (asset.type == AssetType.TEMPLATE || asset.embed == false /*|| !usesLime*/) {
				
				var path = PathHelper.combine (destination, asset.targetPath);
				
				PathHelper.mkdir (Path.directory (path));
				FileHelper.copyAsset (asset, path, context);
				
			}
			
		}
		
	}
	
	
	@ignore public override function install ():Void {}
	@ignore public override function rebuild ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}