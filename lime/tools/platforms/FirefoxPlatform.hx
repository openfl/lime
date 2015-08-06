package lime.tools.platforms;


import lime.tools.helpers.DeploymentHelper;
import lime.tools.helpers.FileHelper;
import lime.tools.helpers.HTML5Helper;
import lime.tools.helpers.IconHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.LogHelper;
import lime.project.HXProject;
import lime.project.Icon;
import sys.FileSystem;


class FirefoxPlatform extends HTML5Platform {
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map <String, String>) {
		
		super (command, _project, targetFlags);
		
	}
	
	
	public override function clean ():Void {
		
		if (FileSystem.exists (targetDirectory)) {
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public override function deploy ():Void {
		
		DeploymentHelper.deploy (project, targetFlags, targetDirectory, "Firefox");
		
	}
	
	
	private override function initialize (command:String, project:HXProject):Void {
		
		targetDirectory = project.app.path + "/firefox";
		outputFile = targetDirectory + "/bin/" + project.app.file + ".js";
		
	}
	
	
	public override function run ():Void {
		
		HTML5Helper.launch (project, project.app.path + "/firefox/bin");
		
	}
	
	
	public override function update ():Void {
		
		super.update ();
		
		var destination = targetDirectory + "/bin/";
		var context = project.templateContext;
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "firefoxos/hxml", destination, context, true, false);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "firefoxos/template", destination, context, true, false);
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "firefox/hxml", destination, context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "firefox/template", destination, context);
		
		var sizes = [ 32, 48, 60, 64, 128, 512 ];
		var icons = project.icons;
		
		if (icons.length == 0) {
			
			icons = [ new Icon (PathHelper.findTemplate (project.templatePaths, "default/icon.svg")) ];
			
		}
		
		for (size in sizes) {
			
			IconHelper.createIcon (icons, size, size, PathHelper.combine (destination, "icon-" + size + ".png"));
			
		}
		
	}
	
	
	@ignore public override function install ():Void {}
	@ignore public override function rebuild ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}