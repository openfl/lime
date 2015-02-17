package lime.tools.helpers;


import lime.project.HXProject;


class DeploymentHelper {
	
	
	public static function deploy (project:HXProject, targetFlags:Map <String, String>, targetDirectory:String) {
		
		var name = project.meta.title + " (" + project.meta.version + ").zip";
		var targetPath = PathHelper.combine (targetDirectory, name);
		
		ZipHelper.compress (PathHelper.combine (targetDirectory, "bin"), targetPath);
		
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