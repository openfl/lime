package platforms;


import helpers.FileHelper;
import helpers.HTML5Helper;
import helpers.IconHelper;
import helpers.PathHelper;
import helpers.LogHelper;
import project.HXProject;
import sys.FileSystem;


class FirefoxPlatform extends HTML5Platform {
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map <String, String>) {
		
		super (command, _project, targetFlags);
		
	}
	
	
	public override function clean ():Void {
		
		var targetPath = project.app.path + "/firefox";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	private override function initialize (command:String, project:HXProject):Void {
		
		outputDirectory = project.app.path + "/firefox";
		outputFile = outputDirectory + "/bin/" + project.app.file + ".js";
		
	}
	
	
	public override function run ():Void {
		
		HTML5Helper.launch (project, project.app.path + "/firefox/bin");
		
	}
	
	
	public override function update ():Void {
		
		super.update ();
		
		var destination = outputDirectory + "/bin/";
		var context = project.templateContext;
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "firefoxos/hxml", destination, context, true, false);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "firefoxos/template", destination, context, true, false);
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "firefox/hxml", destination, context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "firefox/template", destination, context);
		
		var sizes = [ 32, 48, 60, 64, 128, 512 ];
		
		for (size in sizes) {
			
			IconHelper.createIcon (project.icons, size, size, PathHelper.combine (destination, "icon-" + size + ".png"));
			
		}
		
	}
	
	
	@ignore public override function install ():Void {}
	@ignore public override function rebuild ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}