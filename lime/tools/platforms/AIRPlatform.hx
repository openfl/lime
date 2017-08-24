package lime.tools.platforms;


import lime.project.Platform;
import lime.project.PlatformType;
import lime.tools.helpers.AIRHelper;
import lime.tools.helpers.DeploymentHelper;
import lime.tools.helpers.FileHelper;
import lime.tools.helpers.IconHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.LogHelper;
import lime.project.HXProject;
import lime.project.Icon;
import sys.FileSystem;


class AIRPlatform extends FlashPlatform {
	
	
	private var targetPlatform:Platform;
	private var targetPlatformType:PlatformType;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map<String, String>) {
		
		super (command, _project, targetFlags);
		
		targetDirectory = PathHelper.combine (project.app.path, project.config.getString ("air.output-directory", "air/" + buildType));
		targetPlatform = PlatformHelper.hostPlatform;
		targetPlatformType = DESKTOP;
		
	}
	
	
	public override function build ():Void {
		
		super.build ();
		
		if (!project.defines.exists ("AIR_SDK")) {
			
			LogHelper.error ("You must define AIR_SDK with the path to your AIR SDK");
			
		}
		
		if (targetPlatformType != DESKTOP || project.targetFlags.exists ("final")) {
			
			var files = [ project.app.file + ".swf" ];
			for (asset in project.assets) {
				
				if (asset.embed == false && asset.type != TEMPLATE) {
					
					files.push (asset.targetPath);
					
				}
				
			}
			
			AIRHelper.build (project, targetPlatform, targetDirectory + "/bin", project.app.file + ".air", "application.xml", files);
			
		}
		
	}
	
	
	public override function clean ():Void {
		
		if (FileSystem.exists (targetDirectory)) {
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public override function deploy ():Void {
		
		DeploymentHelper.deploy (project, targetFlags, targetDirectory, "AIR");
		
	}
	
	
	public override function run ():Void {
		
		AIRHelper.run (project, targetPlatform, targetDirectory + "/bin");
		
	}
	
	
	public override function update ():Void {
		
		super.update ();
		
		var context = project.templateContext;
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "air/hxml", targetDirectory + "/haxe", context, true, false);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "air/template", targetDirectory + "/bin", context);
		
		//var sizes = [ 32, 48, 60, 64, 128, 512 ];
		//var icons = project.icons;
		//
		//if (icons.length == 0) {
			//
			//icons = [ new Icon (PathHelper.findTemplate (project.templatePaths, "default/icon.svg")) ];
			//
		//}
		//
		//for (size in sizes) {
			//
			//IconHelper.createIcon (icons, size, size, PathHelper.combine (destination, "icon-" + size + ".png"));
			//
		//}
		
	}
	
	
	@ignore public override function install ():Void {}
	@ignore public override function rebuild ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}