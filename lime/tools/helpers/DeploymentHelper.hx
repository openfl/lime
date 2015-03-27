package lime.tools.helpers;


import lime.project.HXProject;


class DeploymentHelper {
	
	
	public static function deploy (project:HXProject, targetFlags:Map <String, String>, targetDirectory:String, targetName:String) {
		
		var name = project.meta.title + " (" + project.meta.version + " build " + project.meta.buildNumber + ") (" + targetName + ").zip";
		var targetPath = PathHelper.combine (targetDirectory, name);
		
		ZipHelper.compress (PathHelper.combine (targetDirectory, "bin"), targetPath);
		
		var cwd = Sys.getCwd();
		if (targetPath.indexOf(cwd) == -1)
		{
			targetPath = PathHelper.combine(cwd, targetPath);
		}
		
		if (targetFlags.exists ("gdrive")) {
			
			var parent = targetFlags.get ("parent");
			
			if (parent != null && parent != "") {
				
				ProcessHelper.runCommand ("", "drive", [ "upload", "-f", targetPath, "-p", parent ]);
				
			} else {
				
				ProcessHelper.runCommand ("", "drive", [ "upload", "-f", targetPath ]);
				
			}
			
		}
		
	}
	
	
}