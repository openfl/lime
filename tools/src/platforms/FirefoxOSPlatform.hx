package platforms;


import helpers.FileHelper;
import helpers.HTML5Helper;
import helpers.IconHelper;
import helpers.PathHelper;
import project.HXProject;
import sys.FileSystem;


class FirefoxOSPlatform extends HTML5Platform {
	
	
	public override function clean (project:HXProject):Void {
		
		var targetPath = project.app.path + "/firefoxos";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	private override function initialize (project:HXProject):Void {
		
		outputDirectory = project.app.path + "/firefoxos";
		outputFile = outputDirectory + "/bin/" + project.app.file + ".js";
		
	}
	
	
	public override function run (project:HXProject, arguments:Array < String > ):Void {
		
		initialize (project);
		
		HTML5Helper.launch (project, project.app.path + "/firefoxos/bin");
		
	}
	
	
	public override function update (project:HXProject):Void {
		
		super.update (project);
		
		var destination = outputDirectory + "/bin/";
		var context = project.templateContext;
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "firefoxos/hxml", destination, context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "firefoxos/template", destination, context);
		
		var sizes = [ 30, 60, 128 ];
		
		for (size in sizes) {
			
			IconHelper.createIcon (project.icons, size, size, PathHelper.combine (destination, "icon-" + size + ".png"));
			
		}
		
	}
	
	
	public function new () {
		
		super ();
		
	}
	
	
}